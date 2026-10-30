import AVFoundation
import Foundation

/// Hält `AVSpeechSynthesizer`, kümmert sich um Stimmwahl, Fertig-Callback
/// und meldet Zeichen-Fortschritt an die Lesepille.
///
/// Mehrere TODOs für die nächsten Iterationen:
/// - Stimm-Auswahl aus den Settings übernehmen
/// - Audio-Export über `write(_:toBufferCallback:)` in eine `.m4a`
@MainActor
final class SpeechService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var finished: (() -> Void)?

    /// Wird bei jedem `willSpeakRangeOfSpeechString` mit der Zeichen-Position
    /// des Range-Endes aufgerufen. Für die Fortschritts-Anzeige der Pille.
    var onProgress: ((Int) -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, voice: AVSpeechSynthesisVoice? = nil, done: (() -> Void)? = nil) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        finished = done
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       willSpeakRangeOfSpeechString characterRange: NSRange,
                                       utterance: AVSpeechUtterance) {
        let location = characterRange.location + characterRange.length
        Task { @MainActor in
            self.onProgress?(location)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.finished?()
            self.finished = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.finished?()
            self.finished = nil
        }
    }
}
