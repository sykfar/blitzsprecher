import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    var selectedMode: ReadingMode = .plain
    var lastText: String = ""

    /// Pfad des zuletzt in den Vault abgelegten `.m4a` — damit der Menü-Bar-
    /// Eintrag „im Finder zeigen" einen Angriffspunkt hat.
    var lastExportURL: URL?

    /// Live-Status während der Wiedergabe. Beobachtet die Lesepille.
    let progress = ReadingProgress()

    /// Shortcuts pro Modus. Einstiegspunkt für die Settings-UI; aktuell
    /// liest `AppState` beim Start die Defaults aus `HotkeyShortcut.defaults`.
    var shortcuts: [ReadingMode: HotkeyShortcut] = HotkeyShortcut.defaults

    let speech = SpeechService()
    let vault = VaultStorage()
    private let hotkeys = HotkeyService()
    private let pill = ReadingPillController()
    private let export = AudioExportService()
    private let dialog = ExportDialogController()
    private var tokens: [ReadingMode: HotkeyService.Token] = [:]

    var isReading: Bool { progress.isReading }

    init() {
        pill.attach(progress: progress) { [weak self] in
            self?.stop()
        }
        speech.onProgress = { [weak self] location in
            self?.progress.updateLocation(location)
        }
        registerAllHotkeys()
    }

    // MARK: - Lesen und Exportieren

    func read(_ text: String, mode: ReadingMode) {
        lastText = text
        selectedMode = mode

        switch mode {
        case .plain, .smoothed, .summary:
            startSpeech(text: text, mode: mode)
        case .export:
            startExport(text: text)
        }
    }

    func stop() {
        speech.stop()
        export.cancel()
        progress.stop()
        pill.hide()
    }

    /// Vom Hotkey ausgelöst: liest den aktuell markierten Text im Modus `mode`.
    /// Fehlt die Auswahl (etwa weil die Accessibility-Berechtigung fehlt),
    /// nimmt die App einen Beispielsatz, damit der Hotkey sichtbar reagiert.
    func readSelection(in mode: ReadingMode) {
        let text = SelectionReader.currentSelection()
                   ?? "Hier würde Blitzsprecher den markierten Text vorlesen."
        read(text, mode: mode)
    }

    // MARK: - Hotkeys

    func registerAllHotkeys() {
        unregisterAllHotkeys()
        for mode in ReadingMode.allCases {
            guard let shortcut = shortcuts[mode] else { continue }
            let token = hotkeys.register(shortcut) { [weak self] in
                self?.readSelection(in: mode)
            }
            if let token { tokens[mode] = token }
        }
    }

    func unregisterAllHotkeys() {
        for token in tokens.values {
            hotkeys.unregister(token)
        }
        tokens.removeAll()
    }

    /// Setzt für `mode` einen neuen Shortcut und meldet die Hotkeys neu an.
    func setShortcut(_ shortcut: HotkeyShortcut, for mode: ReadingMode) {
        shortcuts[mode] = shortcut
        registerAllHotkeys()
    }

    // MARK: - Private

    private func startSpeech(text: String, mode: ReadingMode) {
        progress.start(mode: mode, text: text)
        pill.show()
        speech.speak(text) { [weak self] in
            Task { @MainActor in
                self?.progress.stop()
                self?.pill.hide()
            }
        }
    }

    private func startExport(text: String) {
        let url = ExportLocation.defaultURL()
        progress.start(mode: .export, text: text)
        pill.show()
        export.export(text, to: url) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.progress.stop()
                self.pill.hide()
                switch result {
                case .success(let fileURL):
                    self.presentExportDialog(fileURL: fileURL, text: text)
                case .failure(let error):
                    NSLog("Blitzsprecher: Export fehlgeschlagen — \(error.localizedDescription)")
                }
            }
        }
    }

    private func presentExportDialog(fileURL: URL, text: String) {
        let meta = ExportResult(url: fileURL, text: text, mode: .export, createdAt: Date())
        dialog.present(
            result: meta,
            vault: vault,
            commit: { [weak self] options in
                self?.commitExport(meta, options: options)
            },
            cancel: {
                // Datei bleibt in Downloads — der Nutzer kann sie dort weiter nutzen.
            }
        )
    }

    private func commitExport(_ result: ExportResult, options: ExportCommitOptions) {
        guard options.target == .vault else { return }
        do {
            let receipt = try VaultSink.deliver(result, vault: vault, options: options)
            lastExportURL = receipt.audio
            if options.openAfter {
                NSWorkspace.shared.activateFileViewerSelecting([receipt.audio])
            }
        } catch {
            NSLog("Blitzsprecher: Vault-Ablage fehlgeschlagen — \(error.localizedDescription)")
        }
    }
}

enum ReadingMode: String, CaseIterable, Identifiable {
    case plain
    case smoothed
    case export
    case summary

    var id: String { rawValue }

    var name: String {
        switch self {
        case .plain:    "Blitzsprecher"
        case .smoothed: "Blitzsprecher+"
        case .export:   "Blitzsprecher 🎧"
        case .summary:  "Blitzsprecher 📝"
        }
    }

    var hint: String {
        switch self {
        case .plain:    "Markierten Text vorlesen"
        case .smoothed: "Text erst glätten, dann vorlesen"
        case .export:   "Als Audio-Datei ablegen"
        case .summary:  "Lange Texte: Zusammenfassung vorlesen"
        }
    }
}
