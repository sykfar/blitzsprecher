import SwiftUI

struct ModeRow: View {
    let mode: ReadingMode
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Meridian.Palette.fathom)
                    .frame(width: 22, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.name)
                        .font(Meridian.Typo.sans(13, weight: .semibold))
                        .foregroundStyle(Meridian.Palette.ink)
                    Text(mode.hint)
                        .font(Meridian.Typo.sans(11))
                        .foregroundStyle(Meridian.Palette.ink3)
                }

                Spacer()

                Text(mode.shortcut)
                    .font(Meridian.Typo.mono(10))
                    .foregroundStyle(Meridian.Palette.ink2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Meridian.Palette.paper2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Meridian.Palette.lineStrong, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? Meridian.Palette.paper2 : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isActive ? Meridian.Palette.lineStrong : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var icon: String {
        switch mode {
        case .plain:    "text.quote"
        case .smoothed: "wand.and.stars"
        case .export:   "waveform.circle"
        case .summary:  "doc.text.magnifyingglass"
        }
    }
}
