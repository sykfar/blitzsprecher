import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("Allgemein", systemImage: "gearshape") }
            VoicesTab()
                .tabItem { Label("Stimmen", systemImage: "person.wave.2") }
            ModesTab()
                .tabItem { Label("Modi", systemImage: "square.stack.3d.up") }
            StorageTab()
                .tabItem { Label("Ablage", systemImage: "externaldrive") }
        }
        .frame(width: 540, height: 420)
    }
}

private struct GeneralTab: View {
    var body: some View {
        Form {
            Text("Shortcuts, Lesepille, Updates.")
                .foregroundStyle(Meridian.Palette.ink2)
                .font(Meridian.Typo.sans(13))
        }
        .padding(20)
    }
}

private struct VoicesTab: View {
    var body: some View {
        Form {
            Text("System-Stimmen, Siri-Stimmen, Personal Voice.")
                .foregroundStyle(Meridian.Palette.ink2)
                .font(Meridian.Typo.sans(13))
        }
        .padding(20)
    }
}

private struct ModesTab: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section {
                ForEach(ReadingMode.allCases) { mode in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.name)
                                .font(Meridian.Typo.sans(13, weight: .semibold))
                                .foregroundStyle(Meridian.Palette.ink)
                            Text(mode.hint)
                                .font(Meridian.Typo.sans(11))
                                .foregroundStyle(Meridian.Palette.ink3)
                        }
                        Spacer()
                        if let shortcut = state.shortcuts[mode] {
                            Text(shortcut.description)
                                .font(Meridian.Typo.mono(12))
                                .foregroundStyle(Meridian.Palette.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Meridian.Palette.paper2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Meridian.Palette.lineStrong, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Globale Shortcuts")
                    .font(Meridian.Typo.sans(13, weight: .semibold))
            } footer: {
                Text("Shortcut-Recorder folgt. Für den Moment sind die Defaults ⌃⌥⌘1 bis ⌃⌥⌘4 fest. `fn`-basierte Shortcuts wie bei Blitztext brauchen einen `CGEventTap`; der kommt mit der nächsten Welle.")
                    .font(Meridian.Typo.sans(11))
                    .foregroundStyle(Meridian.Palette.ink3)
            }
        }
        .padding(20)
    }
}

private struct StorageTab: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vault-Ordner")
                            .font(Meridian.Typo.sans(13, weight: .semibold))
                        if let root = state.vault.vaultRoot {
                            Text(root.path)
                                .font(Meridian.Typo.mono(11))
                                .foregroundStyle(Meridian.Palette.ink2)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("Noch nicht gewählt")
                                .font(Meridian.Typo.sans(11))
                                .foregroundStyle(Meridian.Palette.ink3)
                        }
                    }
                    Spacer()
                    Button("Ändern …") {
                        Task { await state.vault.chooseVault() }
                    }
                }
                HStack {
                    Text("Audio-Unterordner")
                        .font(Meridian.Typo.sans(12))
                        .foregroundStyle(Meridian.Palette.ink2)
                    Spacer()
                    Text(state.vault.audioSubfolder)
                        .font(Meridian.Typo.mono(11))
                        .foregroundStyle(Meridian.Palette.ink)
                }
                HStack {
                    Text("Daily-Notes-Ordner")
                        .font(Meridian.Typo.sans(12))
                        .foregroundStyle(Meridian.Palette.ink2)
                    Spacer()
                    Text(state.vault.dailyNotesFolder)
                        .font(Meridian.Typo.mono(11))
                        .foregroundStyle(Meridian.Palette.ink)
                }
            } header: {
                Text("Vault")
                    .font(Meridian.Typo.sans(13, weight: .semibold))
            } footer: {
                Text("Die Audio-Datei landet im Audio-Unterordner des Vaults, die Verlinkung in der Daily Note des Tages.")
                    .font(Meridian.Typo.sans(11))
                    .foregroundStyle(Meridian.Palette.ink3)
            }

            Section {
                Text("GitHub (Repo + Release-Asset) und Website (Ghost-API) kommen in einer späteren Welle. Das Mockup zeigt die Ziele, der Dialog markiert sie heute als Später.")
                    .font(Meridian.Typo.sans(12))
                    .foregroundStyle(Meridian.Palette.ink3)
            } header: {
                Text("Weitere Ziele")
                    .font(Meridian.Typo.sans(13, weight: .semibold))
            }
        }
        .padding(20)
    }
}
