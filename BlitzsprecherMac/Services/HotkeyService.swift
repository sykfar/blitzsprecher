import AppKit
import Foundation

/// Globale Hotkeys für die vier Modi.
///
/// Noch Platzhalter — die reale Umsetzung lehnt sich an die Blitztext-Variante an
/// und nutzt Carbon-Hotkeys (`RegisterEventHotKey`) für systemweite Shortcuts.
/// Für das Grundgerüst reicht die Schnittstelle; der Carbon-Teil kommt mit der
/// ersten echten Lese-Pipeline.
@MainActor
final class HotkeyService {
    typealias Handler = (ReadingMode) -> Void

    private var handler: Handler?

    func register(_ handler: @escaping Handler) {
        self.handler = handler
        // TODO: Carbon-Hotkey-Registrierung
    }

    func unregister() {
        handler = nil
        // TODO: Carbon-Hotkey-Freigabe
    }
}
