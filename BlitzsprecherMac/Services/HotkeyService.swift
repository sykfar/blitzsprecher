import AppKit
import Carbon.HIToolbox
import Foundation

/// Globale Hotkeys über Carbon (`RegisterEventHotKey`).
///
/// Carbon kann die Tasten `⌘ ⌥ ⌃ ⇧` als Modifier sehen, die `fn`-Taste nicht.
/// Blitztext löst `fn`-Shortcuts über einen `CGEventTap`; das bauen wir in
/// einem zweiten Schritt nach. Für den ersten Wurf nutzt Blitzsprecher
/// `⌃⌥⌘1`…`⌃⌥⌘4` als sichere Default-Shortcuts; der Nutzer kann sie später
/// in den Einstellungen ändern.
///
/// Nutzung:
/// ```swift
/// let service = HotkeyService()
/// let token = service.register(.init(keyCode: UInt32(kVK_ANSI_1),
///                                    modifiers: HotkeyShortcut.defaultModifiers)) {
///     // Hotkey gedrückt
/// }
/// service.unregister(token)
/// ```
@MainActor
final class HotkeyService {

    typealias Handler = () -> Void

    struct Token: Hashable {
        fileprivate let id: UInt32
    }

    // MARK: - State

    private var handlers: [UInt32: Handler] = [:]
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var nextId: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?

    // Keine deinit-Aufräumarbeit: Carbon-Hotkeys und Event-Handler leben
    // bis zum Prozessende, und ein nonisolated deinit darf in Swift 6 nicht
    // auf MainActor-isolierten State zugreifen. Wer sauber abmelden will,
    // ruft `unregisterAll()` vor dem Freigeben auf.

    // MARK: - Public API

    /// Registriert einen globalen Hotkey. Gibt ein Token zurück, mit dem er
    /// wieder abgemeldet werden kann, oder `nil`, wenn die Registrierung
    /// scheiterte (meist ein Konflikt mit einem anderen Hotkey auf dem System).
    @discardableResult
    func register(_ shortcut: HotkeyShortcut, handler: @escaping Handler) -> Token? {
        installEventHandlerIfNeeded()

        let id = nextId
        nextId += 1

        let hotKeyId = EventHotKeyID(signature: Self.signature, id: id)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyId,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let ref = hotKeyRef else {
            NSLog("Blitzsprecher: RegisterEventHotKey failed (status \(status)) for \(shortcut)")
            return nil
        }

        refs[id] = ref
        handlers[id] = handler
        return Token(id: id)
    }

    func unregister(_ token: Token) {
        if let ref = refs[token.id] {
            UnregisterEventHotKey(ref)
        }
        refs.removeValue(forKey: token.id)
        handlers.removeValue(forKey: token.id)
    }

    func unregisterAll() {
        for ref in refs.values {
            UnregisterEventHotKey(ref)
        }
        refs.removeAll()
        handlers.removeAll()
    }

    // MARK: - Carbon-Plumbing

    /// Vier-Zeichen-Signatur „BLSP". Hilft nur beim Debuggen in Instruments
    /// und darf ruhig fest sein — kollidiert nicht mit anderen Apps.
    private static let signature: OSType = {
        var code: OSType = 0
        for byte in "BLSP".utf8 { code = (code << 8) + OSType(byte) }
        return code
    }()

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let callback: EventHandlerUPP = { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }

            var hotKeyId = EventHotKeyID()
            let err = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyId
            )
            guard err == noErr else { return OSStatus(eventNotHandledErr) }

            // `Unmanaged` holt uns die Service-Instanz zurück; der Call findet
            // auf dem Main-Thread statt, weil Carbon-Hotkey-Events dort
            // zugestellt werden. Trotzdem markieren wir die Hop auf MainActor
            // explizit, damit Strict Concurrency zufrieden ist.
            let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
            let handlerId = hotKeyId.id
            Task { @MainActor in
                service.handlers[handlerId]?()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
    }
}

// MARK: - Shortcut-Beschreibung

/// Beschreibt einen globalen Shortcut: Keycode plus Modifier-Flags im
/// Carbon-Format (`cmdKey`, `optionKey`, `controlKey`, `shiftKey`).
struct HotkeyShortcut: Hashable, Codable, CustomStringConvertible {
    let keyCode: UInt32
    let modifiers: UInt32

    /// Default-Modifier für Blitzsprecher: `⌃⌥⌘`. Konfliktarm und mit einer Hand
    /// (am linken Daumen-Rand der Tastatur) erreichbar.
    static let defaultModifiers: UInt32 =
        UInt32(controlKey) | UInt32(optionKey) | UInt32(cmdKey)

    /// Darstellung für Menüs und Settings: `⌃⌥⌘1`.
    var description: String {
        var out = ""
        if modifiers & UInt32(controlKey) != 0 { out += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { out += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { out += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { out += "⌘" }
        out += Self.keyLabel(for: keyCode)
        return out
    }

    private static func keyLabel(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_1: "1"
        case kVK_ANSI_2: "2"
        case kVK_ANSI_3: "3"
        case kVK_ANSI_4: "4"
        case kVK_ANSI_5: "5"
        case kVK_ANSI_S: "S"
        case kVK_Return: "⏎"
        case kVK_Space:  "␣"
        case kVK_Escape: "⎋"
        default:         "·"
        }
    }
}

extension HotkeyShortcut {
    /// Vorgaben pro Modus. Lassen sich später in den Settings überschreiben.
    static let defaults: [ReadingMode: HotkeyShortcut] = [
        .plain:    .init(keyCode: UInt32(kVK_ANSI_1), modifiers: defaultModifiers),
        .smoothed: .init(keyCode: UInt32(kVK_ANSI_2), modifiers: defaultModifiers),
        .export:   .init(keyCode: UInt32(kVK_ANSI_3), modifiers: defaultModifiers),
        .summary:  .init(keyCode: UInt32(kVK_ANSI_4), modifiers: defaultModifiers),
    ]
}
