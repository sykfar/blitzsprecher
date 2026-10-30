import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    var selectedMode: ReadingMode = .plain
    var lastText: String = ""
    var isReading: Bool = false
    var currentProgress: Double = 0

    let speech = SpeechService()

    func read(_ text: String, mode: ReadingMode) {
        lastText = text
        selectedMode = mode
        isReading = true
        speech.speak(text) { [weak self] in
            Task { @MainActor in
                self?.isReading = false
            }
        }
    }

    func stop() {
        speech.stop()
        isReading = false
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

    var shortcut: String {
        switch self {
        case .plain:    "fn ⇧"
        case .smoothed: "fn ⌃"
        case .export:   "fn ⌥"
        case .summary:  "fn ⌘"
        }
    }
}
