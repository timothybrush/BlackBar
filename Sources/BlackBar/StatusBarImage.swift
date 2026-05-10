import AppKit

enum StatusBarImage {
    static func renderGraph(history: [Int], active: Int) -> NSImage {
        let size = NSSize(width: 58, height: 22)
        let image = NSImage(size: size)
        image.lockFocusFlipped(false)

        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        let graphRect = NSRect(x: 0, y: 3, width: size.width - 2, height: 16)
        drawGraph(
            history: history,
            in: graphRect,
            active: active,
            activeColor: NSColor.labelColor,
            inactiveColor: NSColor.labelColor.withAlphaComponent(0.35)
        )

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private static func drawGraph(history: [Int], in rect: NSRect, active: Int, activeColor: NSColor, inactiveColor: NSColor) {
        let values = Array(history.suffix(18))
        let maxValue = max(values.max() ?? active, active, 1)
        let barWidth: CGFloat = 2
        let spacing: CGFloat = 1
        let startX = rect.maxX - CGFloat(values.count) * (barWidth + spacing)

        inactiveColor.setStroke()
        let baseline = NSBezierPath()
        baseline.move(to: NSPoint(x: rect.minX, y: rect.minY))
        baseline.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        baseline.stroke()

        for (index, value) in values.enumerated() {
            let height = max(CGFloat(2), rect.height * CGFloat(value) / CGFloat(maxValue))
            let x = max(rect.minX, startX + CGFloat(index) * (barWidth + spacing))
            let y = rect.minY
            let barRect = NSRect(x: x, y: y, width: barWidth, height: height)
            let path = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
            (value == 0 ? inactiveColor : activeColor).setFill()
            path.fill()
        }
    }
}
