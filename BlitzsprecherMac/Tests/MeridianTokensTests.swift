import XCTest
@testable import Blitzsprecher

final class MeridianTokensTests: XCTestCase {

    func test_modes_have_distinct_shortcuts() {
        let shortcuts = ReadingMode.allCases.map(\.shortcut)
        XCTAssertEqual(Set(shortcuts).count, shortcuts.count,
                       "Jeder Modus braucht einen eigenen Shortcut.")
    }

    func test_modes_have_names() {
        for mode in ReadingMode.allCases {
            XCTAssertFalse(mode.name.isEmpty, "\(mode) ohne Name")
            XCTAssertFalse(mode.hint.isEmpty, "\(mode) ohne Hint")
        }
    }

    func test_meridian_radii_increase() {
        XCTAssertLessThan(Meridian.Radius.s, Meridian.Radius.m)
        XCTAssertLessThan(Meridian.Radius.m, Meridian.Radius.l)
    }
}
