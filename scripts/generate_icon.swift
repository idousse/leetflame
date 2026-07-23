// Renders the LeetFlame pixel-flame app icon (dark squircle + flame bitmap)
// at all sizes required for an .icns. Run via scripts/make_icns.sh.
import AppKit

let bitmap: [[Int]] = [
    [0, 0, 0, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 0, 0],
    [0, 0, 1, 2, 1, 0, 0],
    [0, 1, 2, 2, 2, 1, 0],
    [0, 1, 2, 2, 2, 2, 0],
    [1, 2, 3, 3, 3, 2, 1],
    [1, 3, 3, 3, 3, 3, 1],
    [0, 1, 3, 3, 3, 1, 0],
]

func pixelColor(_ v: Int) -> NSColor? {
    switch v {
    case 1: return NSColor(red: 0xFF/255, green: 0xD2/255, blue: 0x4A/255, alpha: 1)
    case 2: return NSColor(red: 0xFF/255, green: 0xA1/255, blue: 0x16/255, alpha: 1)
    case 3: return NSColor(red: 0xFF/255, green: 0x5D/255, blue: 0x3B/255, alpha: 1)
    default: return nil
    }
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // macOS icons float inside the canvas with ~10% margin on each side.
    let margin = size * 0.10
    let tileRect = NSRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)
    let tileRadius = tileRect.width * 0.23
    let tile = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)

    let gradient = NSGradient(
        starting: NSColor(red: 0x22/255, green: 0x25/255, blue: 0x2E/255, alpha: 1),
        ending: NSColor(red: 0x15/255, green: 0x17/255, blue: 0x1D/255, alpha: 1)
    )!
    gradient.draw(in: tile, angle: -70)

    let cols = bitmap[0].count
    let rows = bitmap.count
    // Flame occupies ~62% of tile width, centered.
    let cellUnit = tileRect.width * 0.62 / CGFloat(cols)
    let gap = cellUnit * 0.18
    let cell = cellUnit - gap
    let flameWidth = CGFloat(cols) * cellUnit - gap
    let flameHeight = CGFloat(rows) * cellUnit - gap
    let originX = tileRect.midX - flameWidth / 2
    let originY = tileRect.midY - flameHeight / 2

    for (r, row) in bitmap.enumerated() {
        for (c, v) in row.enumerated() {
            guard let color = pixelColor(v) else { continue }
            let rect = NSRect(
                x: originX + CGFloat(c) * cellUnit,
                y: originY + CGFloat(rows - 1 - r) * cellUnit,
                width: cell,
                height: cell
            )
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cell * 0.28, yRadius: cell * 0.28).fill()
        }
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, size: Int, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let outDir = CommandLine.arguments[1]
for (name, px) in [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
] {
    savePNG(drawIcon(size: CGFloat(px)), size: px, to: "\(outDir)/\(name).png")
}
print("PNGs written to \(outDir)")
