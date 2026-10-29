import Foundation
import IOBluetooth

/// Convertit un axe brut 12 bits en octet DSU (128 = centre).
struct AxisCalibration {
    var center: Int?
    var range = 1000

    mutating func map(_ raw: Int) -> UInt8 {
        if center == nil { center = abs(raw - 0x800) < 300 ? raw : 0x800 }
        let deviation = raw - center!
        range = max(range, abs(deviation))
        return UInt8(clamping: 128 + deviation * 127 / range)
    }
}

/// Relie jusqu’à quatre manettes à quatre emplacements DSU.
final class Bridge {
    enum Phase: Equatable { case idle, searching, connecting, ready, demo }

    let server = DSUServer()
    var verbose = false {
        didSet { server.verbose = verbose; controllers.forEach { $0.verbose = verbose } }
    }
    var onPhase: ((Phase) -> Void)?
    var onUpdate: ((ProState, DSUServer.Pad) -> Void)?
    var onDeviceFound: ((FoundDevice) -> Void)?
    var onDSUClient: ((Bool) -> Void)?

    private(set) var phase: Phase = .idle {
        didSet { if phase != oldValue { onPhase?(phase) } }
    }
    private var controllers: [ProController] = []
    private var controllerPhases: [Phase] = []
    private var reservedAddresses = Set<String>()
    private var axes = [[AxisCalibration]](repeating: [AxisCalibration](repeating: AxisCalibration(), count: 4), count: 4)
    private var heartbeat: Timer?
    private var demoTimer: Timer?

    func listen(port: UInt16) throws {
        try server.listen(port: port)
        server.onClientActivity = { [weak self] active in self?.onDSUClient?(active) }
        log("Serveur DSU à l’écoute sur 127.0.0.1:\(port) (4 emplacements).")
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.server.broadcast() }
        RunLoop.main.add(timer, forMode: .common)
        heartbeat = timer
    }

    func start(address: String?, demo: Bool) {
        stop()
        if demo {
            startDemo()
            return
        }

        let addresses: [String?]
        if let address, !address.isEmpty {
            addresses = [address]
        } else {
            let paired = ProController.pairedControllerAddresses().prefix(4).map(Optional.some)
            addresses = paired.isEmpty ? [nil] : Array(paired)
        }
        reservedAddresses = Set(addresses.compactMap { $0 }.map(Self.normalizedAddress))
        for (slot, address) in addresses.enumerated() {
            let ignored = address.map { reservedAddresses.subtracting([Self.normalizedAddress($0)]) } ?? reservedAddresses
            addController(address: address, slot: slot, ignoringAddresses: ignored)
        }
        log("Manettes Nintendo préparées : \(controllers.count)/4 emplacement(s) DSU.")
        refreshPhase()
    }

    private static func normalizedAddress(_ address: String) -> String {
        address.filter { $0 != ":" && $0 != "-" }.lowercased()
    }

    private func addController(address: String?, slot: Int, ignoringAddresses: Set<String>, searchImmediately: Bool = false) {
        let controller = ProController(address: address, ignoringAddresses: ignoringAddresses, searchImmediately: searchImmediately)
        controller.verbose = verbose
        controller.onConnection = { [weak self] connected, address in
            self?.setConnected(connected, address: address, slot: slot)
            self?.refreshPhase()
        }
        controller.onState = { [weak self] state in self?.publish(state, slot: slot) }
        controller.onDeviceFound = { [weak self] device in
            guard let self else { return }
            if device.looksLikeController { self.reservedAddresses.insert(Self.normalizedAddress(device.address)) }
            self.onDeviceFound?(device)
        }
        controller.onPhase = { [weak self] phase in
            guard let self, self.controllerPhases.indices.contains(slot) else { return }
            switch phase {
            case .idle: self.controllerPhases[slot] = .idle
            case .searching: self.controllerPhases[slot] = .searching
            case .connecting: self.controllerPhases[slot] = .connecting
            case .ready: self.controllerPhases[slot] = .ready
            }
            self.refreshPhase()
        }
        controllers.append(controller)
        controllerPhases.append(.idle)
        controller.start()
    }

    func addController() {
        guard controllers.count < 4 else {
            log("Les quatre emplacements DSU sont déjà utilisés.")
            return
        }
        let slot = controllers.count
        let paired = Set(ProController.pairedControllerAddresses().map(Self.normalizedAddress))
        let ignored = reservedAddresses.union(paired)
        log("Recherche d’une autre manette : appuyez sur SYNC pour l’emplacement DSU \(slot + 1).")
        addController(address: nil, slot: slot, ignoringAddresses: ignored, searchImmediately: true)
    }

    /// Connexion manuelle à un appareil précis.
    func connect(address: String) {
        if let slot = controllerPhases.firstIndex(of: .searching), controllers.indices.contains(slot) {
            controllers[slot].connect(address: address)
        } else {
            start(address: address, demo: false)
        }
    }

    func stop() {
        for controller in controllers { controller.stop() }
        controllers.removeAll()
        controllerPhases.removeAll()
        reservedAddresses.removeAll()
        for slot in 0..<4 { setConnected(false, address: nil, slot: slot) }
        if demoTimer != nil {
            demoTimer?.invalidate()
            demoTimer = nil
            log("Mode démo arrêté.")
        }
        phase = .idle
    }

    private func refreshPhase() {
        if demoTimer != nil { phase = .demo }
        else if controllerPhases.contains(.ready) { phase = .ready }
        else if controllerPhases.contains(.connecting) { phase = .connecting }
        else if controllerPhases.contains(.searching) { phase = .searching }
        else { phase = .idle }
    }

    private func startDemo() {
        log("Mode démo : manette simulée sur l’emplacement 1.")
        setConnected(true, address: "00:00:00:00:00:01", slot: 0)
        phase = .demo
        var tick = 0
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            tick += 1
            let angle = Double(tick) / 60 * 2 * .pi / 4
            var state = ProState()
            if (tick / 60) % 2 == 1 { state.buttons.insert(.a) }
            state.lx = 0x800 + Int(1000 * cos(angle))
            state.ly = 0x800 + Int(1000 * sin(angle))
            self?.publish(state, slot: 0)
        }
        RunLoop.main.add(timer, forMode: .common)
        demoTimer = timer
    }

    private func setConnected(_ connected: Bool, address: String?, slot: Int) {
        let wasConnected = server.connectedSlots[slot]
        var mac = [UInt8](repeating: 0, count: 6)
        if let address {
            mac = address.split(whereSeparator: { $0 == ":" || $0 == "-" }).compactMap { UInt8($0, radix: 16) }
            if mac.count != 6 { mac = [0, 0, 0, 0, 0, 1] }
        }
        server.set(slot: slot, connected: connected, pad: connected ? server.pads[slot] : DSUServer.Pad(), mac: mac)
        if connected && !wasConnected {
            log("Manette prête sur l’emplacement DSU \(slot + 1) (\(address ?? "adresse inconnue")).")
        } else if !connected && wasConnected {
            log("Manette retirée de l’emplacement DSU \(slot + 1).")
        }
        if !connected {
            axes[slot] = [AxisCalibration](repeating: AxisCalibration(), count: 4)
            if slot == 0 { onUpdate?(ProState(), DSUServer.Pad()) }
        }
    }

    private func publish(_ state: ProState, slot: Int) {
        var pad = DSUServer.Pad()
        let buttons = state.buttons
        if buttons.contains(.left)   { pad.buttons1 |= 0x80 }
        if buttons.contains(.down)   { pad.buttons1 |= 0x40 }
        if buttons.contains(.right)  { pad.buttons1 |= 0x20 }
        if buttons.contains(.up)     { pad.buttons1 |= 0x10 }
        if buttons.contains(.plus)   { pad.buttons1 |= 0x08 }
        if buttons.contains(.rStick) { pad.buttons1 |= 0x04 }
        if buttons.contains(.lStick) { pad.buttons1 |= 0x02 }
        if buttons.contains(.minus)  { pad.buttons1 |= 0x01 }
        if buttons.contains(.y)      { pad.buttons2 |= 0x80 }
        if buttons.contains(.b)      { pad.buttons2 |= 0x40 }
        if buttons.contains(.a)      { pad.buttons2 |= 0x20 }
        if buttons.contains(.x)      { pad.buttons2 |= 0x10 }
        if buttons.contains(.r)      { pad.buttons2 |= 0x08 }
        if buttons.contains(.l)      { pad.buttons2 |= 0x04 }
        if buttons.contains(.zr)     { pad.buttons2 |= 0x02 }
        if buttons.contains(.zl)     { pad.buttons2 |= 0x01 }
        pad.ps = buttons.contains(.home) ? 1 : 0
        pad.lx = axes[slot][0].map(state.lx)
        pad.ly = axes[slot][1].map(state.ly)
        pad.rx = axes[slot][2].map(state.rx)
        pad.ry = axes[slot][3].map(state.ry)
        server.set(slot: slot, connected: true, pad: pad, mac: server.macs[slot])
        server.broadcast()
        if slot == 0 { onUpdate?(state, pad) }
    }
}
