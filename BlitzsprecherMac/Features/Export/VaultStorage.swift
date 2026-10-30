import AppKit
import Foundation
import Observation

/// Hält die Vault-bezogenen Einstellungen in `UserDefaults`: Wurzelpfad des
/// Obsidian-Vaults, Audio-Unterordner, Daily-Notes-Ordner.
///
/// Die App läuft bewusst ohne Sandbox (siehe `Entitlements`), deshalb reicht
/// ein einfacher Pfad-String — Security-Scoped Bookmarks sind nicht nötig.
@Observable
@MainActor
final class VaultStorage {

    private enum Keys {
        static let vaultRoot        = "vaultRootPath"
        static let audioSubfolder   = "vaultAudioSubfolder"
        static let dailyNotesFolder = "vaultDailyNotesFolder"
    }

    private let defaults: UserDefaults

    private(set) var vaultRoot: URL?
    private(set) var audioSubfolder: String
    private(set) var dailyNotesFolder: String

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let path = defaults.string(forKey: Keys.vaultRoot), !path.isEmpty {
            self.vaultRoot = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            self.vaultRoot = nil
        }
        self.audioSubfolder   = defaults.string(forKey: Keys.audioSubfolder)   ?? "07 Anhänge/Audio"
        self.dailyNotesFolder = defaults.string(forKey: Keys.dailyNotesFolder) ?? "05 Daily Notes"
    }

    // MARK: - Setzen

    func setVaultRoot(_ url: URL?) {
        vaultRoot = url
        if let url {
            defaults.set(url.path, forKey: Keys.vaultRoot)
        } else {
            defaults.removeObject(forKey: Keys.vaultRoot)
        }
    }

    func setAudioSubfolder(_ value: String) {
        audioSubfolder = value
        defaults.set(value, forKey: Keys.audioSubfolder)
    }

    func setDailyNotesFolder(_ value: String) {
        dailyNotesFolder = value
        defaults.set(value, forKey: Keys.dailyNotesFolder)
    }

    // MARK: - Abgeleitete Pfade

    func audioFolder() -> URL? {
        vaultRoot?.appendingPathComponent(audioSubfolder, isDirectory: true)
    }

    func audioDestination(for filename: String) -> URL? {
        audioFolder()?.appendingPathComponent(filename)
    }

    func dailyNoteURL(for date: Date = Date()) -> URL? {
        guard let root = vaultRoot else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return root.appendingPathComponent(dailyNotesFolder, isDirectory: true)
                   .appendingPathComponent("\(formatter.string(from: date)).md")
    }

    /// Relativer Pfad zur Vault-Wurzel, für Wikilinks oder `![[…]]`-Embeds.
    func relativePath(for url: URL) -> String? {
        guard let root = vaultRoot else { return nil }
        let rootPath = root.standardizedFileURL.path
        let full = url.standardizedFileURL.path
        guard full.hasPrefix(rootPath + "/") else { return nil }
        return String(full.dropFirst(rootPath.count + 1))
    }

    // MARK: - NSOpenPanel

    /// Öffnet einen Ordner-Picker und speichert das Ergebnis als Vault-Root.
    func chooseVault() async {
        let panel = NSOpenPanel()
        panel.title = "Vault wählen"
        panel.message = "Wähle den Ordner deines Obsidian-Vaults."
        panel.prompt = "Als Vault verwenden"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        let response = await panel.beginAsync()
        if response == .OK, let url = panel.url {
            setVaultRoot(url)
        }
    }
}

private extension NSOpenPanel {
    func beginAsync() async -> NSApplication.ModalResponse {
        await withCheckedContinuation { continuation in
            self.begin { response in
                continuation.resume(returning: response)
            }
        }
    }
}
