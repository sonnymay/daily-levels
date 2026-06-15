import AppKit

// usage: swift compose.swift device.png out.png "Line 1" "Line 2"
let a = CommandLine.arguments
let devPath = a[1], outPath = a[2], l1 = a[3], l2 = a[4]

let W = 1290, H = 2796
func rgb(_ r: Int, _ g: Int, _ b: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
}
let cream = rgb(0xF3, 0xF0, 0xE8)
let ink   = rgb(0x1B, 0x1B, 0x1D)
let green = rgb(0x5E, 0x8C, 0x3E)

guard let devRep = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: devPath))),
      let devCG = devRep.cgImage else { fatalError("cannot load \(devPath)") }

// Crop the status bar + Dynamic Island (~152px) and home indicator (~40px) so it merges
// cleanly into the cream canvas (no floating island pill).
let crop = devCG.cropping(to: CGRect(x: 0, y: 152, width: devCG.width, height: devCG.height - 192))!
let targetW = 1010.0
let scale = targetW / Double(crop.width)
let destW = targetW, destH = Double(crop.height) * scale
let destX = (Double(W) - destW) / 2
let destY = 90.0   // bottom margin (origin is bottom-left)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gctx
let ctx = gctx.cgContext

// Background
ctx.setFillColor(cream.cgColor)
ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

// Device (subtle drop shadow for separation)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 28, color: NSColor.black.withAlphaComponent(0.18).cgColor)
ctx.draw(crop, in: CGRect(x: destX, y: destY, width: destW, height: destH))
ctx.restoreGState()

// Captions (origin bottom-left; top of canvas is large y)
func drawCentered(_ s: String, y: CGFloat, color: NSColor) {
    let style = NSMutableParagraphStyle(); style.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 84, weight: .bold),
        .foregroundColor: color,
        .paragraphStyle: style,
    ]
    let str = NSAttributedString(string: s, attributes: attrs)
    let size = str.size()
    str.draw(at: CGPoint(x: (CGFloat(W) - size.width)/2, y: y))
}
drawCentered(l1, y: CGFloat(H) - 300, color: ink)
drawCentered(l2, y: CGFloat(H) - 410, color: green)

NSGraphicsContext.restoreGraphicsState()

let out = rep.representation(using: .png, properties: [:])!
try! out.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
