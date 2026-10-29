import Foundation

/// Un fichier par lancement, commun à l’app et au CLI. Ne détruit jamais un essai précédent.
enum DiagnosticLog {
    private static let lock = NSLock()
    static let url: URL = {
        let env = ProcessInfo.processInfo.environment["WIIUPRO_LOG_DIR"]
        let project = Bundle.main.url(forResource: "project-path", withExtension: "txt")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WiiU Pro", isDirectory: true)
            .appendingPathComponent("logs", isDirectory: true)
        let root: URL
        if let env {
            root = URL(fileURLWithPath: env, isDirectory: true)
        } else if project == "WIIUPRO_APP_SUPPORT" {
            root = appSupport
        } else {
            root = URL(fileURLWithPath: project ?? FileManager.default.currentDirectoryPath, isDirectory: true)
                .appendingPathComponent("logs", isDirectory: true)
        }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return root.appendingPathComponent("sync-\(stamp)-\(ProcessInfo.processInfo.processIdentifier).log")
    }()
    private static let handle: FileHandle? = {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return try FileHandle(forWritingTo: url)
        } catch {
            fputs("Impossible de créer le journal \(url.path): \(error)\n", stderr)
            return nil
        }
    }()
    static func write(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        handle?.write(Data((line + "\n").utf8))
    }
}
