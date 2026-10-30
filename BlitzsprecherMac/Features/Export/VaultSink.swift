import AppKit
import Foundation

/// Legt eine exportierte Audio-Datei im Obsidian-Vault ab:
/// - verschiebt die `.m4a` in den konfigurierten Audio-Unterordner,
/// - schreibt optional ein Transcript (`.md` mit dem gelesenen Text),
/// - hängt optional eine Verlinkungs-Zeile an die Tages-Note.
///
/// Reiner Dateisystem-Code, keine Netzwerk-Calls — läuft komplett lokal.
enum VaultSink {

    enum SinkError: Error, LocalizedError {
        case noVault
        case moveFailed(underlying: Error)
        case transcriptFailed(underlying: Error)
        case dailyNoteFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .noVault:                        "Es ist noch kein Vault ausgewählt."
            case .moveFailed(let e):              "Audio-Datei konnte nicht verschoben werden: \(e.localizedDescription)"
            case .transcriptFailed(let e):        "Transcript konnte nicht geschrieben werden: \(e.localizedDescription)"
            case .dailyNoteFailed(let e):         "Daily Note konnte nicht aktualisiert werden: \(e.localizedDescription)"
            }
        }
    }

    struct Receipt {
        let audio: URL
        let transcript: URL?
        let dailyNote: URL?
    }

    @MainActor
    static func deliver(_ result: ExportResult,
                        vault: VaultStorage,
                        options: ExportCommitOptions,
                        now: Date = Date()) throws -> Receipt {
        guard let audioFolder = vault.audioFolder() else { throw SinkError.noVault }

        do {
            try FileManager.default.createDirectory(at: audioFolder,
                                                    withIntermediateDirectories: true)
        } catch {
            throw SinkError.moveFailed(underlying: error)
        }

        let targetFilename = result.suggestedVaultFilename()
        let targetURL = uniqueURL(for: audioFolder.appendingPathComponent(targetFilename))

        do {
            try FileManager.default.moveItem(at: result.url, to: targetURL)
        } catch {
            throw SinkError.moveFailed(underlying: error)
        }

        var transcriptURL: URL?
        if options.addTranscript {
            let url = targetURL.deletingPathExtension().appendingPathExtension("md")
            do {
                try buildTranscript(for: result).write(to: url, atomically: true, encoding: .utf8)
                transcriptURL = url
            } catch {
                throw SinkError.transcriptFailed(underlying: error)
            }
        }

        var dailyNoteURL: URL?
        if options.linkInDailyNote,
           let noteURL = vault.dailyNoteURL(for: now) {
            do {
                try appendDailyNote(noteURL: noteURL, audioURL: targetURL, vault: vault, now: now)
                dailyNoteURL = noteURL
            } catch {
                throw SinkError.dailyNoteFailed(underlying: error)
            }
        }

        if options.openAfter {
            NSWorkspace.shared.activateFileViewerSelecting([targetURL])
        }

        return Receipt(audio: targetURL, transcript: transcriptURL, dailyNote: dailyNoteURL)
    }

    // MARK: - Intern

    static func uniqueURL(for proposed: URL) -> URL {
        var candidate = proposed
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let stem = proposed.deletingPathExtension().lastPathComponent
            let ext = proposed.pathExtension
            let name = "\(stem) (\(counter)).\(ext)"
            candidate = proposed.deletingLastPathComponent().appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }

    static func buildTranscript(for result: ExportResult) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let header = """
        ---
        type: hörfassung
        date: \(formatter.string(from: result.createdAt))
        quelle: Blitzsprecher
        modus: \(result.mode.rawValue)
        ---

        """
        return header + result.text + "\n"
    }

    @MainActor
    static func appendDailyNote(noteURL: URL,
                                audioURL: URL,
                                vault: VaultStorage,
                                now: Date) throws {
        try FileManager.default.createDirectory(at: noteURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)

        let relativePath = vault.relativePath(for: audioURL) ?? audioURL.path
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "de_DE_POSIX")
        timeFormatter.dateFormat = "HH:mm"
        let line = "- \(timeFormatter.string(from: now)) Hörfassung: ![[\(relativePath)]]\n"

        if let existing = try? String(contentsOf: noteURL, encoding: .utf8) {
            let separator = existing.hasSuffix("\n") ? "" : "\n"
            try (existing + separator + line).write(to: noteURL, atomically: true, encoding: .utf8)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "de_DE_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let title = "# \(dateFormatter.string(from: now))\n\n"
            try (title + line).write(to: noteURL, atomically: true, encoding: .utf8)
        }
    }
}
