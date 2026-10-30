import XCTest
@testable import Blitzsprecher

final class MeridianTokensTests: XCTestCase {

    func test_default_shortcuts_cover_all_modes_and_are_distinct() {
        let shortcuts = ReadingMode.allCases.compactMap { HotkeyShortcut.defaults[$0] }
        XCTAssertEqual(shortcuts.count, ReadingMode.allCases.count,
                       "Jeder Modus braucht einen Default-Shortcut.")
        XCTAssertEqual(Set(shortcuts).count, shortcuts.count,
                       "Default-Shortcuts müssen eindeutig sein.")
    }

    func test_shortcut_description_renders_modifiers() {
        let s = HotkeyShortcut(keyCode: 18, // kVK_ANSI_1
                               modifiers: HotkeyShortcut.defaultModifiers)
        XCTAssertEqual(s.description, "⌃⌥⌘1")
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
