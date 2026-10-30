import XCTest
import AVFoundation
@testable import Blitzsprecher

@MainActor
final class AudioExportServiceTests: XCTestCase {

    func test_default_url_lands_under_downloads_blitzsprecher_folder() {
        let url = ExportLocation.defaultURL()
        XCTAssertEqual(url.pathExtension, "m4a")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Blitzsprecher")
        XCTAssertTrue(url.path.contains("/Downloads/"))
    }

    func test_filename_timestamp_is_sortable_and_filesystem_safe() {
        let now = Date(timeIntervalSince1970: 1_762_000_000) // 2025-11-01 ca.
        let stamp = ExportLocation.filenameTimestamp(from: now)
        XCTAssertEqual(stamp.count, 19)
        XCTAssertFalse(stamp.contains(":"))
        XCTAssertFalse(stamp.contains("/"))
        XCTAssertEqual(stamp.prefix(4).count, 4)
    }

    func test_export_writes_a_playable_m4a() async throws {
        let service = AudioExportService()
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("blitzsprecher-test-\(UUID().uuidString).m4a")

        try? FileManager.default.removeItem(at: tmp)

        let url: URL = try await withCheckedThrowingContinuation { cont in
            service.export("Hallo Welt. Dies ist ein Test für Blitzsprecher.", to: tmp) { result in
                cont.resume(with: result.mapError { $0 as Error })
            }
        }

        XCTAssertEqual(url, tmp)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmp.path))

        let asset = AVURLAsset(url: tmp)
        let duration = try await asset.load(.duration)
        XCTAssertGreaterThan(CMTimeGetSeconds(duration), 0.3,
                             "Die exportierte Datei sollte Audio enthalten.")

        try? FileManager.default.removeItem(at: tmp)
    }
}
