import AVFoundation
import AppKit
import Foundation

/// Exportiert gesprochenen Text in eine `.m4a`-Datei.
///
/// Nutzt `AVSpeechSynthesizer.write(_:toBufferCallback:)` statt `speak(_:)`:
/// die Buffer-Variante liefert PCM-Frames in Blöcken statt direkt auf die
/// Audio-Ausgabe zu gehen. Beim ersten Buffer bauen wir die `AVAudioFile`
/// mit AAC in MP4; ein Buffer mit `frameLength == 0` signalisiert das Ende.
@MainActor
final class AudioExportService {

    enum ExportError: Error, LocalizedError {
        case buildFailed(underlying: Error)
        case writeFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .buildFailed(let error):
                "Audio-Datei konnte nicht angelegt werden: \(error.localizedDescription)"
            case .writeFailed(let error):
                "Audio-Buffer konnte nicht geschrieben werden: \(error.localizedDescription)"
            }
        }
    }

    /// Der Synth lebt für die Dauer eines Exports; das Callback hält eine
    /// schwache Referenz nicht aus, deshalb halten wir ihn hier.
    private var synthesizer: AVSpeechSynthesizer?
    private var outputFile: AVAudioFile?
    private var destination: URL?
    private var completion: ((Result<URL, ExportError>) -> Void)?

    /// Startet den Export. `completion` wird beim ersten erfolgreichen letzten
    /// Buffer (`frameLength == 0`) aufgerufen oder sofort bei einem Fehler.
    func export(_ text: String,
                voice: AVSpeechSynthesisVoice? = nil,
                to url: URL,
                completion: @escaping (Result<URL, ExportError>) -> Void) {
        let synth = AVSpeechSynthesizer()
        self.synthesizer = synth
        self.outputFile = nil
        self.destination = url
        self.completion = completion

        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synth.write(utterance) { [weak self] audioBuffer in
            Task { @MainActor in
                self?.consume(audioBuffer)
            }
        }
    }

    func cancel() {
        synthesizer?.stopSpeaking(at: .immediate)
        teardown()
    }

    // MARK: - Intern

    private func consume(_ buffer: AVAudioBuffer) {
        guard let pcm = buffer as? AVAudioPCMBuffer, let url = destination else { return }

        if pcm.frameLength == 0 {
            // Letzter Buffer: Datei schließen, Erfolg melden.
            outputFile = nil
            let done = completion
            teardown()
            done?(.success(url))
            return
        }

        if outputFile == nil {
            do {
                outputFile = try buildFile(at: url, matching: pcm.format)
            } catch {
                let done = completion
                teardown()
                done?(.failure(.buildFailed(underlying: error)))
                return
            }
        }

        do {
            try outputFile?.write(from: pcm)
        } catch {
            let done = completion
            teardown()
            done?(.failure(.writeFailed(underlying: error)))
        }
    }

    private func buildFile(at url: URL, matching pcmFormat: AVAudioFormat) throws -> AVAudioFile {
        let settings: [String: Any] = [
            AVFormatIDKey:            kAudioFormatMPEG4AAC,
            AVSampleRateKey:          pcmFormat.sampleRate,
            AVNumberOfChannelsKey:    Int(pcmFormat.channelCount),
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        return try AVAudioFile(forWriting: url, settings: settings,
                               commonFormat: .pcmFormatFloat32, interleaved: false)
    }

    private func teardown() {
        synthesizer = nil
        outputFile = nil
        destination = nil
        completion = nil
    }
}

/// Erzeugt einen Standard-Zielpfad für einen frischen Export:
/// `~/Downloads/Blitzsprecher/YYYY-MM-DD HH-MM-SS.m4a`.
enum ExportLocation {
    static func defaultURL(now: Date = Date()) -> URL {
        let downloads = FileManager.default.urls(for: .downloadsDirectory,
                                                 in: .userDomainMask).first
                        ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
        let folder = downloads.appendingPathComponent("Blitzsprecher", isDirectory: true)
        return folder.appendingPathComponent("\(filenameTimestamp(from: now)).m4a")
    }

    static func filenameTimestamp(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter.string(from: date)
    }
}
