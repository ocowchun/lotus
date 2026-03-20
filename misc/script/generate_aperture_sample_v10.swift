import AppKit

let size = CGSize(width: 1024, height: 1024)
let outputURL = URL(fileURLWithPath: "/Users/ocowchun/projects/swift/lotus/misc/app-icon/lotus-aperture-sample-v10.png")

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
        green: CGFloat((hex >> 8) & 0xFF) / 255.0,
        blue: CGFloat(hex & 0xFF) / 255.0,
        alpha: alpha
    )
}

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func bladePath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat, startDeg: CGFloat, sweepDeg: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    let p1 = CGPoint(
        x: center.x + cos(startDeg * .pi / 180) * innerRadius,
        y: center.y + sin(startDeg * .pi / 180) * innerRadius
    )
    let p2 = CGPoint(
        x: center.x + cos((startDeg + sweepDeg * 0.42) * .pi / 180) * outerRadius,
        y: center.y + sin((startDeg + sweepDeg * 0.42) * .pi / 180) * outerRadius
    )
    let p3 = CGPoint(
        x: center.x + cos((startDeg + sweepDeg) * .pi / 180) * outerRadius,
        y: center.y + sin((startDeg + sweepDeg) * .pi / 180) * outerRadius
    )
    let p4 = CGPoint(
        x: center.x + cos((startDeg + sweepDeg * 0.78) * .pi / 180) * innerRadius,
        y: center.y + sin((startDeg + sweepDeg * 0.78) * .pi / 180) * innerRadius
    )

    path.move(to: p1)
    path.curve(
        to: p2,
        controlPoint1: CGPoint(x: p1.x * 0.88 + center.x * 0.12, y: p1.y * 0.88 + center.y * 0.12),
        controlPoint2: CGPoint(x: p2.x * 0.96 + center.x * 0.04, y: p2.y * 0.96 + center.y * 0.04)
    )
    path.line(to: p3)
    path.curve(
        to: p4,
        controlPoint1: CGPoint(x: p3.x * 0.98 + center.x * 0.02, y: p3.y * 0.98 + center.y * 0.02),
        controlPoint2: CGPoint(x: p4.x * 0.92 + center.x * 0.08, y: p4.y * 0.92 + center.y * 0.08)
    )
    path.close()
    return path
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create bitmap context")
}

bitmap.size = size
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

let canvas = CGRect(origin: .zero, size: size)
let tileRect = canvas.insetBy(dx: 52, dy: 52)
let tile = roundedRectPath(tileRect, radius: 230)

if let background = NSGradient(colors: [
    color(0x212327),
    color(0x343434),
    color(0x242424)
]) {
    background.draw(in: tile, angle: -55)
}

NSGraphicsContext.current?.saveGraphicsState()
let highlight = NSShadow()
highlight.shadowColor = color(0xFFFFFF, alpha: 0.07)
highlight.shadowBlurRadius = 10
highlight.shadowOffset = CGSize(width: 0, height: -2)
highlight.set()
color(0xFFFFFF, alpha: 0.10).setStroke()
tile.lineWidth = 2
tile.stroke()
NSGraphicsContext.current?.restoreGraphicsState()

let center = CGPoint(x: size.width / 2, y: size.height / 2)
let outerRadius: CGFloat = 284
let innerRadius: CGFloat = 126
let bladeCount = 6
let sweep: CGFloat = 360 / CGFloat(bladeCount)
let bladeColors = [
    color(0xD8D8D8),
    color(0xCFCFCF),
    color(0xD6D6D6),
    color(0xC7C7C7),
    color(0xD3D3D3),
    color(0xCBCBCB)
]

for index in 0..<bladeCount {
    let start = -90 + CGFloat(index) * sweep
    let blade = bladePath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startDeg: start,
        sweepDeg: sweep + 8
    )

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x000000, alpha: 0.12)
    shadow.shadowBlurRadius = 12
    shadow.shadowOffset = CGSize(width: 0, height: -8)
    shadow.set()
    bladeColors[index].setFill()
    blade.fill()
    NSGraphicsContext.current?.restoreGraphicsState()
}

let hubRect = CGRect(x: center.x - 74, y: center.y - 74, width: 148, height: 148)
if let hubGradient = NSGradient(colors: [
    color(0x4A4A4A),
    color(0x232323),
    color(0x171717)
]) {
    hubGradient.draw(in: NSBezierPath(ovalIn: hubRect), relativeCenterPosition: .zero)
}

if let centerGlow = NSGradient(colors: [
    color(0x8A8A8A, alpha: 0.35),
    color(0x5A5A5A, alpha: 0.14),
    color(0x101010, alpha: 0.0)
]) {
    centerGlow.draw(
        in: NSBezierPath(ovalIn: CGRect(x: center.x - 118, y: center.y - 118, width: 236, height: 236)),
        relativeCenterPosition: .zero
    )
}

color(0xFFFFFF, alpha: 0.06).setStroke()
let innerRing = NSBezierPath(ovalIn: CGRect(x: center.x - 170, y: center.y - 170, width: 340, height: 340))
innerRing.lineWidth = 2
innerRing.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode png")
}

try data.write(to: outputURL)
