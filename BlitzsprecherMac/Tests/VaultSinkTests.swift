import XCTest
@testable import Blitzsprecher

@MainActor
final class VaultSinkTests: XCTestCase {

    private var vaultRoot: URL!
    private var tmpSource: URL!
    private var vault: VaultStorage!

    override func setUp() async throws {
        try await super.setUp()
        vaultRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("blitzsprecher-vault-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: vaultRoot, withIntermediateDirectories: true)

        tmpSource = FileManager.default.temporaryDirectory
            .appendingPathComponent("blitzsprecher-source-\(UUID().uuidString).m4a")
        try Data(repeating: 0x42, count: 512).write(to: tmpSource)

        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        vault = VaultStorage(defaults: defaults)
        vault.setVaultRoot(vaultRoot)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: vaultRoot)
        try? FileManager.default.removeItem(at: tmpSource)
        try await super.tearDown()
    }

    func test_deliver_moves_file_into_audio_subfolder_and_updates_daily_note() throws {
        let result = ExportResult(url: tmpSource,
                                  text: "Der Herbstwald riecht nach feuchtem Laub.",
                                  mode: .export,
                                  createdAt: Date(timeIntervalSince1970: 1_762_000_000))
        var options = ExportCommitOptions()
        options.addTranscript = true
        options.linkInDailyNote = true

        let receipt = try VaultSink.deliver(result,
                                            vault: vault,
                                            options: options,
                                            now: result.createdAt)

        XCTAssertFalse(FileManager.default.fileExists(atPath: tmpSource.path),
                       "Quell-Datei wurde verschoben, nicht kopiert")
        XCTAssertTrue(FileManager.default.fileExists(atPath: receipt.audio.path))
        XCTAssertTrue(receipt.audio.path.contains("07 Anhänge/Audio"))

        let transcript = try XCTUnwrap(receipt.transcript)
        let transcriptText = try String(contentsOf: transcript, encoding: .utf8)
        XCTAssertTrue(transcriptText.contains("Der Herbstwald riecht"))
        XCTAssertTrue(transcriptText.contains("---"), "Transcript hat Frontmatter")

        let dailyNote = try XCTUnwrap(receipt.dailyNote)
        let noteText = try String(contentsOf: dailyNote, encoding: .utf8)
        XCTAssertTrue(noteText.contains("Hörfassung: ![["))
        XCTAssertTrue(noteText.contains("07 Anhänge/Audio"))
    }

    func test_second_delivery_on_same_day_gets_unique_filename() throws {
        let first = ExportResult(url: tmpSource,
                                 text: "Erster Satz",
                                 mode: .export,
                                 createdAt: Date(timeIntervalSince1970: 1_762_000_000))
        _ = try VaultSink.deliver(first,
                                  vault: vault,
                                  options: ExportCommitOptions(),
                                  now: first.createdAt)

        let secondSource = FileManager.default.temporaryDirectory
            .appendingPathComponent("blitzsprecher-source2-\(UUID().uuidString).m4a")
        try Data(repeating: 0x43, count: 256).write(to: secondSource)
        defer { try? FileManager.default.removeItem(at: secondSource) }

        let second = ExportResult(url: secondSource,
                                  text: "Erster Satz",
                                  mode: .export,
                                  createdAt: first.createdAt)
        let receipt = try VaultSink.deliver(second,
                                            vault: vault,
                                            options: ExportCommitOptions(),
                                            now: first.createdAt)

        XCTAssertTrue(receipt.audio.lastPathComponent.contains("(2)"),
                      "Zweite Ablage am gleichen Tag bekommt (2)-Suffix")
    }

    func test_relative_path_strips_vault_root() {
        let nested = vaultRoot.appendingPathComponent("07 Anhänge/Audio/x.m4a")
        XCTAssertEqual(vault.relativePath(for: nested), "07 Anhänge/Audio/x.m4a")

        let outside = URL(fileURLWithPath: "/tmp/other.m4a")
        XCTAssertNil(vault.relativePath(for: outside))
    }
}
