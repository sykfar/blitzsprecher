import AVFoundation
import Foundation

/// Hält `AVSpeechSynthesizer`, kümmert sich um Stimmwahl und Fertig-Callback.
///
/// Mehrere TODOs für die nächsten Iterationen:
/// - Stimm-Auswahl aus den Settings übernehmen
/// - Fortschritt (`willSpeakRangeOfSpeechString`) an die Lesepille melden
/// - Audio-Export über `write(_:toBufferCallback:)` in eine `.m4a`
@MainActor
final class SpeechService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var finished: (() -> Void)?

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
