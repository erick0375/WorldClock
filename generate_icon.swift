import AppKit
import CoreGraphics

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("No CGContext")
}

// 1. macOS squircle padding (824x824 centered in 1024x1024)
let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185.0
let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 40, color: NSColor.black.withAlphaComponent(0.45).cgColor)
ctx.addPath(squirclePath)
ctx.setFillColor(NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.16, alpha: 1.0).cgColor)
ctx.fillPath()
ctx.restoreGState()

// Clip to squircle
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()

// 2. Deep midnight-indigo to twilight gradient background
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.16, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.10, green: 0.15, blue: 0.32, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.16, green: 0.22, blue: 0.44, alpha: 1.0).cgColor
] as CFArray
let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 512, y: 100),
        end: CGPoint(x: 512, y: 924),
        options: []
    )
}

// 3. Subtle glowing radial aura in the center
let glowColors = [
    NSColor(calibratedRed: 0.20, green: 0.65, blue: 1.0, alpha: 0.28).cgColor,
    NSColor(calibratedRed: 0.20, green: 0.65, blue: 1.0, alpha: 0.0).cgColor
] as CFArray
if let radial = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(
        radial,
        startCenter: CGPoint(x: 512, y: 540),
        startRadius: 0,
        endCenter: CGPoint(x: 512, y: 540),
        endRadius: 380,
        options: [.drawsBeforeStartLocation]
    )
}

// 4. Stylized Globe Latitude & Longitude Grid Lines in background
ctx.saveGState()
let globeCenter = CGPoint(x: 512, y: 512)
let globeRadius: CGFloat = 310
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
ctx.setLineWidth(4)
ctx.strokeEllipse(in: CGRect(x: globeCenter.x - globeRadius, y: globeCenter.y - globeRadius, width: globeRadius * 2, height: globeRadius * 2))

// Meridians
for rx in [100.0, 205.0] {
    let rect = CGRect(x: globeCenter.x - CGFloat(rx), y: globeCenter.y - globeRadius, width: CGFloat(rx * 2), height: globeRadius * 2)
    ctx.strokeEllipse(in: rect)
}
// Parallels
for dy in [-180.0, -90.0, 0.0, 90.0, 180.0] {
    let y = globeCenter.y + CGFloat(dy)
    let halfChord = sqrt(max(0, globeRadius * globeRadius - CGFloat(dy * dy)))
    ctx.move(to: CGPoint(x: globeCenter.x - halfChord, y: y))
    ctx.addLine(to: CGPoint(x: globeCenter.x + halfChord, y: y))
    ctx.strokePath()
}
ctx.restoreGState()

// 5. Draw 4 Multi-Timezone Digital Clock Cards (2x2 Grid inside the icon)
struct MiniCard {
    let rect: CGRect
    let city: String
    let offset: String
    let time: String
    let isDay: Bool
}

let cards: [MiniCard] = [
    MiniCard(rect: CGRect(x: 152, y: 530, width: 344, height: 240), city: "NEW YORK", offset: "-4HRS", time: "09:42", isDay: true),
    MiniCard(rect: CGRect(x: 528, y: 530, width: 344, height: 240), city: "LONDON", offset: "+1HR", time: "14:42", isDay: true),
    MiniCard(rect: CGRect(x: 152, y: 254, width: 344, height: 240), city: "TOKYO", offset: "+9HRS", time: "22:42", isDay: false),
    MiniCard(rect: CGRect(x: 528, y: 254, width: 344, height: 240), city: "SYDNEY", offset: "+11HRS", time: "00:42", isDay: false)
]

for card in cards {
    let cardPath = CGPath(roundedRect: card.rect, cornerWidth: 44, cornerHeight: 44, transform: nil)

    // Card Glass Fill
    ctx.saveGState()
    ctx.addPath(cardPath)
    if card.isDay {
        ctx.setFillColor(NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.18, alpha: 0.18).cgColor)
    } else {
        ctx.setFillColor(NSColor(calibratedRed: 0.28, green: 0.36, blue: 0.88, alpha: 0.24).cgColor)
    }
    ctx.fillPath()

    // Card Border
    ctx.addPath(cardPath)
    if card.isDay {
        ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.28, alpha: 0.55).cgColor)
    } else {
        ctx.setStrokeColor(NSColor(calibratedRed: 0.45, green: 0.62, blue: 1.0, alpha: 0.55).cgColor)
    }
    ctx.setLineWidth(4)
    ctx.strokePath()
    ctx.restoreGState()

    // Day/Night indicator dot/sun/moon
    let dotCenter = CGPoint(x: card.rect.minX + 36, y: card.rect.maxY - 46)
    ctx.saveGState()
    if card.isDay {
        ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.15, alpha: 1.0).cgColor)
    } else {
        ctx.setFillColor(NSColor(calibratedRed: 0.52, green: 0.65, blue: 1.0, alpha: 1.0).cgColor)
    }
    ctx.fillEllipse(in: CGRect(x: dotCenter.x - 11, y: dotCenter.y - 11, width: 22, height: 22))
    ctx.restoreGState()

    // City Label
    let cityAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 25, weight: .bold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.92)
    ]
    let cityStr = NSAttributedString(string: card.city, attributes: cityAttrs)
    cityStr.draw(at: CGPoint(x: card.rect.minX + 58, y: card.rect.maxY - 62))

    // Offset Pill
    let pillRect = CGRect(x: card.rect.maxX - 104, y: card.rect.maxY - 60, width: 80, height: 30)
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 15, cornerHeight: 15, transform: nil)
    ctx.saveGState()
    ctx.addPath(pillPath)
    ctx.setFillColor(
        card.isDay
            ? NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.15, alpha: 0.28).cgColor
            : NSColor(calibratedRed: 0.45, green: 0.58, blue: 1.0, alpha: 0.30).cgColor
    )
    ctx.fillPath()
    ctx.restoreGState()

    let offsetAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
        .foregroundColor: card.isDay
            ? NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.32, alpha: 1.0)
            : NSColor(calibratedRed: 0.68, green: 0.78, blue: 1.0, alpha: 1.0)
    ]
    let offsetStr = NSAttributedString(string: card.offset, attributes: offsetAttrs)
    let offsetSize = offsetStr.size()
    offsetStr.draw(at: CGPoint(
        x: pillRect.midX - offsetSize.width / 2,
        y: pillRect.midY - offsetSize.height / 2
    ))

    // Digital Time Readout
    let timeAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 82, weight: .bold),
        .foregroundColor: NSColor.white
    ]
    let timeStr = NSAttributedString(string: card.time, attributes: timeAttrs)
    let timeSize = timeStr.size()
    timeStr.draw(at: CGPoint(
        x: card.rect.midX - timeSize.width / 2,
        y: card.rect.minY + 38
    ))
}

// 6. Outer Squircle Specular Border
ctx.addPath(squirclePath)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.24).cgColor)
ctx.setLineWidth(6)
ctx.strokePath()

ctx.restoreGState()
image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
}
