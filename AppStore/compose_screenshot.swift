import AppKit

// Usage:
// swift compose_screenshot.swift input.png output.png "Headline" "Subtext" [width] [height]
let arguments = CommandLine.arguments
guard arguments.count >= 5 else {
    fatalError("Expected input, output, headline, and subtext")
}

let inputPath = arguments[1]
let outputPath = arguments[2]
let headline = arguments[3].replacingOccurrences(of: "\\n", with: "\n")
let subtext = arguments[4].replacingOccurrences(of: "\\n", with: "\n")
let width = arguments.count > 5 ? Int(arguments[5]) ?? 1320 : 1320
let height = arguments.count > 6 ? Int(arguments[6]) ?? 2868 : 2868

func color(_ hex: Int) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

let forest = color(0x1B4332)
let cream = color(0xF7F4EC)
let ink = color(0x171918)

guard let sourceRep = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: inputPath))),
      let source = sourceRep.cgImage else {
    fatalError("Could not read \(inputPath)")
}

let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
guard let cg = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
) else {
    fatalError("Could not create output canvas")
}

let context = NSGraphicsContext(cgContext: cg, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

// Every output pixel starts opaque. This prevents transparent simulator masks from becoming black
// blocks after App Store Connect or other image processors flatten the PNG.
cg.setFillColor(cream.cgColor)
cg.fill(CGRect(x: 0, y: 0, width: width, height: height))

let headerHeight = CGFloat(height) * 0.33
cg.setFillColor(forest.cgColor)
cg.fill(CGRect(x: 0, y: CGFloat(height) - headerHeight, width: CGFloat(width), height: headerHeight))

let phoneWidth = CGFloat(width) * 0.76
let phoneHeight = phoneWidth * CGFloat(source.height) / CGFloat(source.width)
let phoneX = (CGFloat(width) - phoneWidth) / 2
let phoneY = max(54, CGFloat(height) - headerHeight - phoneHeight + CGFloat(height) * 0.11)
let phoneRect = CGRect(x: phoneX, y: phoneY, width: phoneWidth, height: phoneHeight)
let bezel = max(14, CGFloat(width) * 0.014)
let cornerRadius = max(52, CGFloat(width) * 0.055)

cg.saveGState()
cg.setShadow(
    offset: CGSize(width: 0, height: -12),
    blur: 34,
    color: NSColor.black.withAlphaComponent(0.2).cgColor
)
cg.setFillColor(ink.cgColor)
cg.addPath(CGPath(roundedRect: phoneRect.insetBy(dx: -bezel, dy: -bezel),
                  cornerWidth: cornerRadius + bezel,
                  cornerHeight: cornerRadius + bezel,
                  transform: nil))
cg.fillPath()
cg.restoreGState()

cg.saveGState()
cg.addPath(CGPath(roundedRect: phoneRect,
                  cornerWidth: cornerRadius,
                  cornerHeight: cornerRadius,
                  transform: nil))
cg.clip()
cg.setFillColor(cream.cgColor)
cg.fill(phoneRect)
cg.setBlendMode(.normal)
cg.draw(source, in: phoneRect)
cg.restoreGState()

func drawCentered(_ text: String, y: CGFloat, height: CGFloat, size: CGFloat, color: NSColor) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineBreakMode = .byWordWrapping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: .bold),
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: text, attributes: attributes).draw(
        with: CGRect(x: CGFloat(width) * 0.08,
                     y: y,
                     width: CGFloat(width) * 0.84,
                     height: height),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
}

drawCentered(
    headline,
    y: CGFloat(height) - headerHeight * 0.48,
    height: headerHeight * 0.3,
    size: CGFloat(width) * 0.06,
    color: cream
)
drawCentered(
    subtext,
    y: CGFloat(height) - headerHeight * 0.68,
    height: headerHeight * 0.18,
    size: CGFloat(width) * 0.029,
    color: cream.withAlphaComponent(0.9)
)

NSGraphicsContext.restoreGraphicsState()

guard let outputImage = cg.makeImage(),
      let png = NSBitmapImageRep(cgImage: outputImage).representation(using: .png, properties: [:]) else {
    fatalError("Could not encode output PNG")
}
try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(width)x\(height) screenshot to \(outputPath)")
