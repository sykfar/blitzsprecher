import Foundation
import Observation

/// Live-Status der Wiedergabe für die Lesepille.
///
/// AVSpeechSynthesizer liefert keine echte Dauer; wir schätzen sie aus der
/// Zeichenzahl (deutsche Faustregel ~ 15 Zeichen pro Sekunde bei
/// Standard-Rate) und zeigen zusätzlich die tatsächlich verstrichene Zeit.
/// `charLocation` meldet der Delegate über `willSpeakRangeOfSpeechString`.
@Observable
@MainActor
final class ReadingProgress {

    private(set) var isReading: Bool = false
    private(set) var mode: ReadingMode = .plain
    private(set) var charLocation: Int = 0
    private(set) var totalChars: Int = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var estimatedTotal: TimeInterval = 0

    private var startedAt: Date?
    private var tick: Task<Void, Never>?

    /// Geschätzte Lesegeschwindigkeit in Zeichen pro Sekunde.
    private let charsPerSecond: Double = 15

    // MARK: - Steuerung

    func start(mode: ReadingMode, text: String) {
        tick?.cancel()
        self.mode = mode
        self.totalChars = max(text.count, 1)
        self.charLocation = 0
        self.elapsed = 0
        self.estimatedTotal = Double(totalChars) / charsPerSecond
        self.startedAt = Date()
        self.isReading = true

        tick = Task { [weak self] in
            while let self, !Task.isCancelled, self.isReading {
                self.recomputeElapsed()
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    func updateLocation(_ location: Int) {
        charLocation = min(max(location, 0), totalChars)
    }

    func stop() {
        isReading = false
        tick?.cancel()
        tick = nil
        startedAt = nil
    }

    // MARK: - Abgeleitete Werte

    var progress: Double {
        guard totalChars > 0 else { return 0 }
        return min(1.0, Double(charLocation) / Double(totalChars))
    }

    var timeLabel: String {
        "\(format(elapsed)) / \(format(max(estimatedTotal, elapsed)))"
    }

    // MARK: - Intern

    private func recomputeElapsed() {
        guard let startedAt else { return }
        elapsed = Date().timeIntervalSince(startedAt)
    }

    private func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

extension ReadingMode {
    /// Kurze, in die Pille passende Bezeichnung.
    var shortName: String {
        switch self {
        case .plain:    "liest"
        case .smoothed: "liest geglättet"
        case .export:   "exportiert"
        case .summary:  "fasst zusammen"
        }
    }
}
