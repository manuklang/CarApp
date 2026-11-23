import Foundation

enum Fmt {
    static func compassPoint(_ degrees: Double) -> String {
        let points = ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
        let idx = Int((degrees.truncatingRemainder(dividingBy: 360) + 360 + 22.5) / 45) % 8
        return points[idx]
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        let h = s / 3600, m = (s % 3600) / 60
        if h > 0 { return String(format: "%d:%02d h", h, m) }
        return String(format: "%d:%02d min", m, s % 60)
    }

    static func number(_ v: Double, digits: Int = 0) -> String {
        let f = NumberFormatter()
        f.locale = Locale.current
        f.numberStyle = .decimal
        f.minimumFractionDigits = digits
        f.maximumFractionDigits = digits
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    static func coordinate(_ value: Double, positive: String, negative: String) -> String {
        let hemi = value >= 0 ? positive : negative
        let a = abs(value)
        let deg = Int(a)
        let minFull = (a - Double(deg)) * 60
        let min = Int(minFull)
        let sec = (minFull - Double(min)) * 60
        return String(format: "%d°%02d'%04.1f\" %@", deg, min, sec, hemi)
    }

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    static let date: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return f
    }()
}
