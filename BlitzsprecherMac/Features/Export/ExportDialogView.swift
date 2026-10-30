import SwiftUI

struct ExportDialogView: View {
    let result: ExportResult
    let vault: VaultStorage
    let onCommit: (ExportCommitOptions) -> Void
    let onCancel: () -> Void

    @State private var options = ExportCommitOptions()
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            quote
            targets
            paths
            optionsBlock
            footer
        }
        .padding(24)
        .frame(width: 560)
        .background(Meridian.Palette.card)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ABLAGE — WOHIN MIT DEM AUDIO?")
                .font(Meridian.Typo.sans(11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Meridian.Palette.ink3)
            Text("Hörfassung speichern")
                .font(Meridian.Typo.serif(22, weight: .medium))
                .foregroundStyle(Meridian.Palette.ink)
            Text("\(result.durationEstimate) · \(result.fileSize) · deutsch · AVSpeech")
                .font(Meridian.Typo.mono(11))
                .foregroundStyle(Meridian.Palette.ink3)
                .tracking(0.3)
        }
    }

    private var quote: some View {
        Text(result.excerpt)
            .font(Meridian.Typo.serif(14))
            .foregroundStyle(Meridian.Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Meridian.Palette.paper2)
            .overlay(
                Rectangle()
                    .fill(Meridian.Palette.fathom)
                    .frame(width: 3),
                alignment: .leading
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var targets: some View {
        HStack(spacing: 10) {
            ForEach([ExportTarget.vault, .github, .website], id: \.self) { target in
                TargetCard(
                    target: target,
                    isSelected: options.target == target
                ) {
                    if target.isAvailable {
                        options.target = target
                    }
                }
            }
        }
    }

    private var paths: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let vaultRoot = vault.vaultRoot {
                PathRow(label: "ZIELPFAD",
                        value: vaultRelative(for: proposedAudioURL(root: vaultRoot)))
                if options.linkInDailyNote,
                   let noteURL = vault.dailyNoteURL() {
                    PathRow(label: "VERLINKEN",
                            value: vaultRelative(for: noteURL))
                }
            } else {
                vaultPickerRow
            }
        }
    }

    private var vaultPickerRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Meridian.Palette.sienna)
            VStack(alignment: .leading, spacing: 2) {
                Text("Kein Vault ausgewählt")
                    .font(Meridian.Typo.sans(13, weight: .semibold))
                    .foregroundStyle(Meridian.Palette.ink)
                Text("Blitzsprecher weiß noch nicht, wohin im Vault die Hörfassung soll.")
                    .font(Meridian.Typo.sans(11))
                    .foregroundStyle(Meridian.Palette.ink3)
            }
            Spacer()
            Button("Vault wählen …") {
                Task { await vault.chooseVault() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Meridian.Palette.fathom)
        }
        .padding(12)
        .background(Meridian.Palette.paper2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Meridian.Palette.sienna.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var optionsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $options.addTranscript) {
                Text("Quelltext als Transcript neben die Audio-Datei legen")
                    .font(Meridian.Typo.sans(13))
                    .foregroundStyle(Meridian.Palette.ink2)
            }
            Toggle(isOn: $options.linkInDailyNote) {
                Text("Verlinkung in die heutige Daily Note anhängen")
                    .font(Meridian.Typo.sans(13))
                    .foregroundStyle(Meridian.Palette.ink2)
            }
            Toggle(isOn: $options.openAfter) {
                Text("Datei nach dem Ablegen im Finder zeigen")
                    .font(Meridian.Typo.sans(13))
                    .foregroundStyle(Meridian.Palette.ink2)
            }
        }
        .toggleStyle(.checkbox)
        .padding(.top, 6)
    }

    private var footer: some View {
        HStack {
            Button("Nicht ablegen, nur in Downloads lassen") {
                onCancel()
            }
            .buttonStyle(.link)
            .foregroundStyle(Meridian.Palette.ink2)
            Spacer()
            Button {
                busy = true
                onCommit(options)
            } label: {
                Text("Ablegen")
                    .font(Meridian.Typo.sans(13, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Meridian.Palette.fathom)
            .disabled(canCommit == false || busy)
        }
    }

    private var canCommit: Bool {
        if options.target == .vault {
            return vault.vaultRoot != nil
        }
        return false
    }

    private func proposedAudioURL(root: URL) -> URL {
        root.appendingPathComponent(vault.audioSubfolder, isDirectory: true)
            .appendingPathComponent(result.suggestedVaultFilename())
    }

    private func vaultRelative(for url: URL) -> String {
        vault.relativePath(for: url) ?? url.path
    }
}

private struct TargetCard: View {
    let target: ExportTarget
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: target.symbolName)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Meridian.Palette.fathom)
                Text(target.title)
                    .font(Meridian.Typo.serif(16, weight: .medium))
                    .foregroundStyle(Meridian.Palette.ink)
                Text(target.hint)
                    .font(Meridian.Typo.sans(11))
                    .foregroundStyle(Meridian.Palette.ink3)
                    .fixedSize(horizontal: false, vertical: true)
                if target.isAvailable == false {
                    Text("Später")
                        .font(Meridian.Typo.mono(9))
                        .tracking(0.8)
                        .foregroundStyle(Meridian.Palette.ink3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Meridian.Palette.paper2)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Meridian.Palette.paper2 : Meridian.Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Meridian.Palette.fathom : Meridian.Palette.line,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(target.isAvailable ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(target.isAvailable == false)
    }
}

private struct PathRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(Meridian.Typo.mono(10))
                .tracking(0.8)
                .foregroundStyle(Meridian.Palette.ink3)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(Meridian.Typo.mono(12))
                .foregroundStyle(Meridian.Palette.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Meridian.Palette.paper2)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .lineLimit(1)
                .truncationMode(.head)
        }
    }
}
