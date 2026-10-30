import XCTest
@testable import Blitzsprecher

@MainActor
final class ReadingProgressTests: XCTestCase {

    func test_start_initialises_counters_and_estimate() {
        let p = ReadingProgress()
        p.start(mode: .plain, text: String(repeating: "a", count: 300))

        XCTAssertTrue(p.isReading)
        XCTAssertEqual(p.mode, .plain)
        XCTAssertEqual(p.totalChars, 300)
        XCTAssertEqual(p.charLocation, 0)
        XCTAssertEqual(p.estimatedTotal, 20.0, accuracy: 0.01,
                       "300 Zeichen ÷ 15 Zeichen/s = 20 s")
        p.stop()
    }

    func test_update_location_clamps_to_total() {
        let p = ReadingProgress()
        p.start(mode: .plain, text: "0123456789")
        p.updateLocation(5)
        XCTAssertEqual(p.charLocation, 5)
        XCTAssertEqual(p.progress, 0.5, accuracy: 0.0001)

        p.updateLocation(999)
        XCTAssertEqual(p.charLocation, 10)
        XCTAssertEqual(p.progress, 1.0, accuracy: 0.0001)

        p.updateLocation(-5)
        XCTAssertEqual(p.charLocation, 0)
        p.stop()
    }

    func test_time_label_formats_minutes_and_seconds() {
        let p = ReadingProgress()
        p.start(mode: .plain, text: String(repeating: "a", count: 450))
        // elapsed ist noch ≈ 0, estimatedTotal = 30 s
        XCTAssertEqual(p.timeLabel, "0:00 / 0:30")
        p.stop()
    }

    func test_stop_marks_not_reading() {
        let p = ReadingProgress()
        p.start(mode: .export, text: "abc")
        XCTAssertTrue(p.isReading)
        p.stop()
        XCTAssertFalse(p.isReading)
    }

    func test_mode_short_name_covers_all_cases() {
        for mode in ReadingMode.allCases {
            XCTAssertFalse(mode.shortName.isEmpty, "\(mode) ohne shortName")
        }
    }
}
