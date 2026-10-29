import AppKit
import Foundation

struct Point {
    let x: CGFloat
    let y: CGFloat
    init(_ x: CGFloat, _ y: CGFloat) { self.x = x; self.y = y }
}

func drawControllerIcon(size: Int) -> Data {
    let edge = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    graphics.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: edge, height: edge).fill()

    let background = NSBezierPath(roundedRect: NSRect(x: edge * 0.035, y: edge * 0.035, width: edge * 0.93, height: edge * 0.93), xRadius: edge * 0.22, yRadius: edge * 0.22)
    NSGradient(colors: [NSColor(calibratedRed: 0.17, green: 0.48, blue: 0.86, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.20, blue: 0.42, alpha: 1)])!.draw(in: background, angle: -45)

    let body = NSBezierPath()
    body.move(to: Point(edge * 0.16, edge * 0.62).nsPoint)
    body.curve(to: Point(edge * 0.84, edge * 0.62).nsPoint, controlPoint1: Point(edge * 0.29, edge * 0.74).nsPoint, controlPoint2: Point(edge * 0.71, edge * 0.74).nsPoint)
    body.curve(to: Point(edge * 0.82, edge * 0.39).nsPoint, controlPoint1: Point(edge * 0.92, edge * 0.58).nsPoint, controlPoint2: Point(edge * 0.91, edge * 0.44).nsPoint)
    body.curve(to: Point(edge * 0.70, edge * 0.31).nsPoint, controlPoint1: Point(edge * 0.77, edge * 0.32).nsPoint, controlPoint2: Point(edge * 0.73, edge * 0.29).nsPoint)
    body.curve(to: Point(edge * 0.63, edge * 0.40).nsPoint, controlPoint1: Point(edge * 0.68, edge * 0.31).nsPoint, controlPoint2: Point(edge * 0.66, edge * 0.38).nsPoint)
    body.curve(to: Point(edge * 0.37, edge * 0.40).nsPoint, controlPoint1: Point(edge * 0.56, edge * 0.46).nsPoint, controlPoint2: Point(edge * 0.44, edge * 0.46).nsPoint)
    body.curve(to: Point(edge * 0.30, edge * 0.31).nsPoint, controlPoint1: Point(edge * 0.34, edge * 0.38).nsPoint, controlPoint2: Point(edge * 0.32, edge * 0.30).nsPoint)
    body.curve(to: Point(edge * 0.18, edge * 0.39).nsPoint, controlPoint1: Point(edge * 0.27, edge * 0.29).nsPoint, controlPoint2: Point(edge * 0.22, edge * 0.32).nsPoint)
    body.curve(to: Point(edge * 0.16, edge * 0.62).nsPoint, controlPoint1: Point(edge * 0.09, edge * 0.46).nsPoint, controlPoint2: Point(edge * 0.09, edge * 0.58).nsPoint)
    body.close()
    NSColor(calibratedWhite: 0.91, alpha: 1).setFill()
    body.fill()
    NSColor(calibratedWhite: 1, alpha: 0.95).setStroke()
    body.lineWidth = edge * 0.014
    body.stroke()

    func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, color: NSColor) {
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: edge * x - edge * radius, y: edge * y - edge * radius, width: edge * radius * 2, height: edge * radius * 2)).fill()
    }
    func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, radius: CGFloat, color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: NSRect(x: edge * x, y: edge * y, width: edge * w, height: edge * h), xRadius: edge * radius, yRadius: edge * radius).fill()
    }

    let ink = NSColor(calibratedRed: 0.11, green: 0.16, blue: 0.24, alpha: 1)
    // D-pad
    rounded(0.205, 0.478, 0.105, 0.044, radius: 0.014, color: ink)
    rounded(0.235, 0.448, 0.044, 0.105, radius: 0.014, color: ink)
    // Two analog sticks
    circle(0.385, 0.59, 0.054, color: NSColor(calibratedWhite: 0.70, alpha: 1))
    circle(0.385, 0.59, 0.036, color: ink)
    circle(0.615, 0.43, 0.054, color: NSColor(calibratedWhite: 0.70, alpha: 1))
    circle(0.615, 0.43, 0.036, color: ink)
    // Face buttons
    circle(0.775, 0.535, 0.031, color: NSColor(calibratedRed: 0.91, green: 0.28, blue: 0.30, alpha: 1))
    circle(0.718, 0.480, 0.031, color: NSColor(calibratedRed: 0.24, green: 0.54, blue: 0.88, alpha: 1))
    circle(0.775, 0.425, 0.031, color: NSColor(calibratedRed: 0.35, green: 0.70, blue: 0.43, alpha: 1))
    circle(0.832, 0.480, 0.031, color: NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.23, alpha: 1))
    // Minus, HOME and plus
    rounded(0.435, 0.335, 0.045, 0.012, radius: 0.006, color: ink)
    circle(0.500, 0.341, 0.025, color: NSColor(calibratedRed: 0.20, green: 0.52, blue: 0.82, alpha: 1))
    rounded(0.520, 0.335, 0.045, 0.012, radius: 0.006, color: ink)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

extension Point {
    var nsPoint: NSPoint { NSPoint(x: x, y: y) }
}

let output = CommandLine.arguments.dropFirst().first ?? "build/AppIcon.icns"
let outputURL = URL(fileURLWithPath: output)
let iconset = outputURL.deletingLastPathComponent().appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
let variants: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, size) in variants {
    try drawControllerIcon(size: size).write(to: iconset.appendingPathComponent(name))
}

let iconRepresentations: [(String, String)] = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_128x128@2x.png"),
    ("ic09", "icon_256x256@2x.png"),
    ("ic10", "icon_512x512@2x.png"),
]
var chunks = Data()
for (type, name) in iconRepresentations {
    let png = try Data(contentsOf: iconset.appendingPathComponent(name))
    chunks.append(contentsOf: type.utf8)
    var chunkLength = UInt32(png.count + 8).bigEndian
    withUnsafeBytes(of: &chunkLength) { chunks.append(contentsOf: $0) }
    chunks.append(png)
}
var icns = Data("icns".utf8)
var fileLength = UInt32(chunks.count + 8).bigEndian
withUnsafeBytes(of: &fileLength) { icns.append(contentsOf: $0) }
icns.append(chunks)
try icns.write(to: outputURL)
try FileManager.default.removeItem(at: iconset)
