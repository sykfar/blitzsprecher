import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 14) {
            readButton

            VStack(spacing: 2) {
                ForEach(ReadingMode.allCases) { mode in
                    ModeRow(
                        mode: mode,
                        shortcut: state.shortcuts[mode],
                        isActive: state.selectedMode == mode
                    ) {
                        state.selectedMode = mode
                        state.readSelection(in: mode)
                    }
                }
            }

            if !state.lastText.isEmpty {
                lastRow
            }

            if !PermissionsService.hasAccessibility {
                accessibilityHint
            }

            Divider()
                .background(Meridian.Palette.line)

            HStack {
                Button("Einstellungen …") { openSettings() }
                    .buttonStyle(.plain)
                    .font(Meridian.Typo.sans(12))
                    .foregroundStyle(Meridian.Palette.ink2)
                Spacer()
                Button("Beenden") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(Meridian.Typo.sans(12))
                    .foregroundStyle(Meridian.Palette.ink3)
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(Meridian.Palette.card)
    }

    private var readButton: some View {
        Button {
            if state.isReading { state.stop() }
            else { state.readSelection(in: state.selectedMode) }
        } label: {
            Circle()
                .fill(Meridian.Palette.fathom)
                .frame(width: 58, height: 58)
                .overlay(
                    Image(systemName: state.isReading ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Meridian.Palette.onFathom)
                )
                .shadow(color: Meridian.Palette.fathom.opacity(0.3), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var lastRow: some View {
        HStack {
            Text(state.lastText)
                .font(Meridian.Typo.serif(13))
                .foregroundStyle(Meridian.Palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button("▶ NOCHMAL") {
                state.read(state.lastText, mode: state.selectedMode)
            }
            .buttonStyle(.plain)
            .font(Meridian.Typo.mono(10))
            .foregroundStyle(Meridian.Palette.fathom)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Meridian.Palette.paper2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Meridian.Palette.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var accessibilityHint: some View {
        Button {
            PermissionsService.requestAccessibility()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Meridian.Palette.sienna)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Markierten Text lesen")
                        .font(Meridian.Typo.sans(12, weight: .semibold))
                        .foregroundStyle(Meridian.Palette.ink)
                    Text("Berechtigung für Bedienungshilfen erteilen")
                        .font(Meridian.Typo.sans(11))
                        .foregroundStyle(Meridian.Palette.ink3)
                }
                Spacer()
            }
            .padding(10)
            .background(Meridian.Palette.paper2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Meridian.Palette.sienna.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }
}
