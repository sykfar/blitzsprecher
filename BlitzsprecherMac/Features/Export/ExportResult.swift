import AVFoundation
import Foundation

/// Metadaten einer frisch exportierten Audio-Datei, wie sie der Ablage-Dialog
/// anzeigt.
///
/// Die Dauer wird aus der Textlänge geschätzt (die exakte Dauer würde einen
/// `AVURLAsset`-Load kosten; für den Dialog reicht der Richtwert).
struct ExportResult: Hashable {
    let url: URL
    let text: String
    let mode: ReadingMode
    let createdAt: Date

    /// Dateigröße als lesbares Label (z. B. „2,4 MB").
    var fileSize: String {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// Geschätzte Dauer (deutsche Faustregel: ~15 Zeichen pro Sekunde).
    var durationEstimate: String {
        let seconds = max(1, Int((Double(text.count) / 15.0).rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// Erste Zeile oder die ersten ~80 Zeichen für den Preview-Block.
    var excerpt: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 180 { return trimmed }
        let prefix = trimmed.prefix(180)
        return prefix + "…"
    }

    /// Vorschlag für einen sprechenden Dateinamen innerhalb des Vaults.
    func suggestedVaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: createdAt)
        let slug = Self.slug(from: text) ?? "Hörfassung"
        return "\(date) – \(slug).m4a"
    }

    private static func slug(from text: String) -> String? {
        let firstSentence = text.split(whereSeparator: { ".!?\n".contains($0) }).first.map(String.init)
            ?? text
        let words = firstSentence.split(separator: " ").prefix(6).joined(separator: " ")
        let cleaned = words.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}

enum ExportTarget: Hashable {
    case vault
    case github
    case website

    var title: String {
        switch self {
        case .vault:   "Vault"
        case .github:  "GitHub"
        case .website: "Website"
        }
    }

    var hint: String {
        switch self {
        case .vault:   "Anhang zur Quellnote, Wikilink in Daily Note"
        case .github:  "Release-Asset oder Issue-Anhang"
        case .website: "Audio-Block in picturefish-Essay"
        }
    }

    var symbolName: String {
        switch self {
        case .vault:   "folder.fill.badge.plus"
        case .github:  "chevron.left.forwardslash.chevron.right"
        case .website: "globe"
        }
    }

    /// Erste Welle: nur Vault ist umgesetzt. GitHub/Website zeigen den Dialog
    /// deaktiviert mit „Später"-Hinweis.
    var isAvailable: Bool {
        self == .vault
    }
}

struct ExportCommitOptions {
    var target: ExportTarget = .vault
    var addTranscript: Bool = true
    var linkInDailyNote: Bool = true
    var openAfter: Bool = false
}
