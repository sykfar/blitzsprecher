import ApplicationServices
import Foundation

/// Liest den markierten Text in der fokussierten Anwendung über die Accessibility-API.
///
/// Noch Platzhalter — die reale Umsetzung braucht:
/// - Accessibility-Berechtigung (`AXIsProcessTrustedWithOptions`)
/// - Robustes Lesen von `kAXSelectedTextAttribute` auf dem Fokus-Element
/// - Fallback über das Clipboard (⌘C in die System-Pasteboard-Kopie, dann wiederherstellen)
enum SelectionReader {
    static func currentSelection() -> String? {
        let systemElement = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(systemElement,
                                            kAXFocusedUIElementAttribute as CFString,
                                            &focused) == .success,
              let focusedElement = focused else { return nil }

        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(focusedElement as! AXUIElement,
                                                   kAXSelectedTextAttribute as CFString,
                                                   &value)
        guard result == .success, let text = value as? String, !text.isEmpty else {
            return nil
        }
        return text
    }
}
