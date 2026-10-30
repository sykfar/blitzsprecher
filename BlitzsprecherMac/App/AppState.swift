import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    var selectedMode: ReadingMode = .plain
    var lastText: String = ""

    /// Live-Status während der Wiedergabe. Beobachtet die Lesepille.
    let progress = ReadingProgress()

    /// Shortcuts pro Modus. Einstiegspunkt für die Settings-UI; aktuell
    /// liest `AppState` beim Start die Defaults aus `HotkeyShortcut.defaults`.
    var shortcuts: [ReadingMode: HotkeyShortcut] = HotkeyShortcut.defaults

    let speech = SpeechService()
    private let hotkeys = HotkeyService()
    private let pill = ReadingPillController()
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

    // MARK: - Lesen

    func read(_ text: String, mode: ReadingMode) {
        lastText = text
        selectedMode = mode
        progress.start(mode: mode, text: text)
        pill.show()
        speech.speak(text) { [weak self] in
            Task { @MainActor in
                self?.progress.stop()
                self?.pill.hide()
            }
        }
    }

    func stop() {
        speech.stop()
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
