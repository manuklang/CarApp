import UIKit
import CarPlay

/// Zeichnet kleine Instrumenten-Grafiken für die CarPlay-Listen.
enum GaugeRenderer {
    static var imageSize: CGSize {
        let s = CPListItem.maximumImageSize
        return CGSize(width: max(s.width, 44), height: max(s.height, 44))
    }

    static func speed(fraction: Double, accent: UIColor, warning: Bool) -> UIImage {
        let size = imageSize
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let c = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            let start = CGFloat.pi * 0.75
            let sweep = CGFloat.pi * 1.5
            let f = CGFloat(min(max(fraction, 0), 1))
            let color = warning ? UIColor.systemRed : accent

            c.setLineCap(.round)
            c.setLineWidth(5)
            c.setStrokeColor(UIColor.gray.withAlphaComponent(0.35).cgColor)
            c.addArc(center: center, radius: radius, startAngle: start, endAngle: start + sweep, clockwise: false)
            c.strokePath()

            if f > 0.001 {
                c.setStrokeColor(color.cgColor)
                c.addArc(center: center, radius: radius, startAngle: start, endAngle: start + sweep * f, clockwise: false)
                c.strokePath()
            }

            // Nadel
            let a = start + sweep * f
            c.setLineWidth(3)
            c.setStrokeColor(color.cgColor)
            c.move(to: center)
            c.addLine(to: CGPoint(x: center.x + cos(a) * radius * 0.75, y: center.y + sin(a) * radius * 0.75))
            c.strokePath()
            c.setFillColor(UIColor.white.cgColor)
            c.fillEllipse(in: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7))
        }
    }

    static func compass(heading: Double?, accent: UIColor) -> UIImage {
        let size = imageSize
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let c = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 3

            c.setLineWidth(2.5)
            c.setStrokeColor(UIColor.gray.withAlphaComponent(0.5).cgColor)
            c.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

            // Pfeil zeigt in Fahrtrichtung relativ zu Norden (oben)
            let angle = CGFloat((heading ?? 0) * .pi / 180)
            c.translateBy(x: center.x, y: center.y)
            c.rotate(by: angle)
            let r = radius * 0.78
            c.setFillColor((heading == nil ? UIColor.gray : accent).cgColor)
            c.move(to: CGPoint(x: 0, y: -r))
            c.addLine(to: CGPoint(x: r * 0.55, y: r * 0.7))
            c.addLine(to: CGPoint(x: 0, y: r * 0.35))
            c.addLine(to: CGPoint(x: -r * 0.55, y: r * 0.7))
            c.closePath()
            c.fillPath()
        }
    }

    static func symbol(_ name: String, color: UIColor? = nil) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        if let color {
            return UIImage(systemName: name, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
        }
        return UIImage(systemName: name, withConfiguration: config.applying(UIImage.SymbolConfiguration.preferringMulticolor()))
    }

    private static var format: UIGraphicsImageRendererFormat {
        let f = UIGraphicsImageRendererFormat()
        f.scale = 3
        f.opaque = false
        return f
    }
}

