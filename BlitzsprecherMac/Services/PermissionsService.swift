import ApplicationServices
import AppKit
import Foundation

/// Prüft und erfragt die Accessibility-Berechtigung.
///
/// Blitzsprecher braucht sie für zwei Dinge:
/// - markierten Text aus anderen Apps über `AXUIElement` lesen,
/// - später: `CGEventTap` für `fn`-basierte Shortcuts.
///
/// Carbon-Hotkeys (`⌃⌥⌘…`) brauchen die Berechtigung **nicht**, deshalb starten
/// die Default-Shortcuts auch ohne Accessibility.
@MainActor
enum PermissionsService {

    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    /// Fragt den Nutzer über den System-Dialog. Gibt `true` zurück, wenn die
    /// Berechtigung schon da ist; sonst erscheint der Dialog und `false`
    /// kommt sofort zurück — der Nutzer entscheidet im Hintergrund.
    @discardableResult
    static func requestAccessibility() -> Bool {
        // Statt `kAXTrustedCheckOptionPrompt.takeUnretainedValue()` (eine
        // globale `var`, die Swift 6 als nicht-concurrency-safe meldet)
        // nutzen wir den dokumentierten Schlüssel direkt — er ist stabil.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Öffnet die Systemeinstellungen auf dem Accessibility-Panel. Nützlich,
    /// wenn der Nutzer die Berechtigung einmal abgelehnt hat; der Dialog
    /// erscheint dann kein zweites Mal.
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
