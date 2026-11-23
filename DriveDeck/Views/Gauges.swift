import SwiftUI

/// Runder Tacho mit Skala und Nadel.
struct SpeedGauge: View {
    var value: Double
    var maxValue: Double
    var unit: String
    var accent: Color
    var warning: Bool

    private let startAngle = 135.0
    private let sweep = 270.0

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = size * 0.06
            let fraction = min(max(value / maxValue, 0), 1)
            let color = warning ? Color.red : accent

            ZStack {
                // Hintergrundbogen
                Circle()
                    .trim(from: 0, to: sweep / 360)
                    .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))
                // Wertbogen
                Circle()
                    .trim(from: 0, to: sweep / 360 * fraction)
                    .stroke(
                        AngularGradient(colors: [color.opacity(0.55), color], center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(sweep * fraction)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(startAngle))
                    .shadow(color: color.opacity(0.6), radius: lineWidth * 0.6)

                // Skala
                ForEach(0...12, id: \.self) { i in
                    let major = i % 2 == 0
                    Capsule()
                        .fill(Color.white.opacity(major ? 0.7 : 0.35))
                        .frame(width: major ? 3 : 2, height: size * (major ? 0.07 : 0.045))
                        .offset(y: -size * 0.34)
                        .rotationEffect(.degrees(startAngle + 90 + sweep * Double(i) / 12))
                }
                ForEach(0...6, id: \.self) { i in
                    let angle = Angle.degrees(startAngle + sweep * Double(i) / 6)
                    Text("\(Int(maxValue * Double(i) / 6))")
                        .font(.system(size: size * 0.05, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .position(x: geo.size.width / 2 + cos(angle.radians) * size * 0.25,
                                  y: geo.size.height / 2 + sin(angle.radians) * size * 0.25)
                }

                // Nadel
                Capsule()
                    .fill(color)
                    .frame(width: size * 0.012 + 2, height: size * 0.36)
                    .offset(y: -size * 0.18)
                    .rotationEffect(.degrees(startAngle + 90 + sweep * fraction))
                    .animation(.easeOut(duration: 0.4), value: fraction)

                VStack(spacing: 0) {
                    Text("\(Int(value.rounded()))")
                        .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(warning ? Color.red : Color.white)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(.system(size: size * 0.065, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .offset(y: size * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Kompassrose, die sich mit der Fahrtrichtung dreht.
struct CompassDial: View {
    var heading: Double?
    var accent: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: size * 0.03)
                ZStack {
                    ForEach(0..<36, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(i % 9 == 0 ? 0.8 : 0.3))
                            .frame(width: i % 9 == 0 ? 2.5 : 1.2, height: size * (i % 9 == 0 ? 0.09 : 0.05))
                            .offset(y: -size * 0.40)
                            .rotationEffect(.degrees(Double(i) * 10))
                    }
                    ForEach(Array(["N", "O", "S", "W"].enumerated()), id: \.offset) { idx, label in
                        Text(label)
                            .font(.system(size: size * 0.13, weight: .bold, design: .rounded))
                            .foregroundStyle(label == "N" ? Color.red : Color.white)
                            .rotationEffect(.degrees(-Double(idx) * 90 + (heading ?? 0)))
                            .offset(y: -size * 0.25)
                            .rotationEffect(.degrees(Double(idx) * 90))
                    }
                }
                .rotationEffect(.degrees(-(heading ?? 0)))
                .animation(.easeOut(duration: 0.3), value: heading ?? 0)

                Triangle()
                    .fill(accent)
                    .frame(width: size * 0.10, height: size * 0.12)
                    .offset(y: -size * 0.47)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.closeSubpath()
        }
    }
}
