import SwiftUI

/// Die Fathom-blaue Lesepille, die während der Wiedergabe unten im Bildschirm
/// schwebt — Spiegel der lila Blitztext-Aufnahmepille, nur eben in umgekehrter
/// Richtung (lesen statt sprechen).
struct ReadingPillView: View {
    let progress: ReadingProgress
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Waveform()
                .frame(width: 24, height: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text("Blitzsprecher \(progress.mode.shortName)")
                    .font(Meridian.Typo.sans(11, weight: .semibold))
                    .foregroundStyle(Meridian.Palette.onFathom)
                Text(progress.timeLabel)
                    .font(Meridian.Typo.mono(10))
                    .foregroundStyle(Meridian.Palette.onFathom.opacity(0.75))
                    .monospacedDigit()
            }

            Divider()
                .frame(width: 1, height: 20)
                .overlay(Meridian.Palette.onFathom.opacity(0.3))

            Button(action: onStop) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Meridian.Palette.onFathom.opacity(0.9))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Lesen stoppen")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Meridian.Palette.fathom)
                .overlay(
                    Capsule()
                        .stroke(Meridian.Palette.onFathom.opacity(0.15), lineWidth: 0.5)
                )
        )
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(Meridian.Palette.onFathom.opacity(0.25))
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Meridian.Palette.onFathom)
                        .frame(width: progressBarWidth(), height: 2)
                        .padding(.leading, 10)
                }
                .offset(y: -3)
        }
        .shadow(color: Meridian.Palette.fathom.opacity(0.35), radius: 14, y: 6)
    }

    private func progressBarWidth() -> CGFloat {
        // Bar ist etwa 230pt breit; -20pt für die Padding-Reserve.
        210 * CGFloat(progress.progress)
    }
}

/// Fünf kleine Striche, die wie eine Audio-Welle pulsen. Rein optisch — die
/// Werte kommen aus der Zeit, nicht aus den Audio-Daten.
private struct Waveform: View {
    private let heights: [CGFloat] = [10, 14, 8, 16, 11]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { context in
            let t = context.date.timeIntervalSince1970
            HStack(spacing: 2) {
                ForEach(Array(heights.enumerated()), id: \.offset) { index, height in
                    let scale = 0.4 + 0.6 * abs(sin(t * 3.0 + Double(index) * 0.6))
                    Capsule()
                        .fill(Meridian.Palette.onFathom)
                        .frame(width: 2, height: height * scale)
                }
            }
            .frame(height: 16)
        }
    }
}
