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
    var body: some View {
        Form {
            Text("Blitzsprecher, +, 🎧, 📝.")
                .foregroundStyle(Meridian.Palette.ink2)
                .font(Meridian.Typo.sans(13))
        }
        .padding(20)
    }
}

private struct StorageTab: View {
    var body: some View {
        Form {
            Section("Vault") {
                Text("Pfad zum Obsidian-Vault, Audio-Unterordner, Verlinkungs-Regel.")
                    .foregroundStyle(Meridian.Palette.ink3)
                    .font(Meridian.Typo.sans(12))
            }
            Section("Website") {
                Text("Ghost-API, Upload-Pfad für Audio-Dateien.")
                    .foregroundStyle(Meridian.Palette.ink3)
                    .font(Meridian.Typo.sans(12))
            }
            Section("GitHub") {
                Text("Repository, Release-Asset oder Issue.")
                    .foregroundStyle(Meridian.Palette.ink3)
                    .font(Meridian.Typo.sans(12))
            }
        }
        .padding(20)
    }
}
