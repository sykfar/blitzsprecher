import AppKit
import SwiftUI

/// Verwaltet das NSPanel der Lesepille: Position, Anzeigen und Verbergen mit
/// weichem Fade, Inhalt per `NSHostingView`.
///
/// Das Panel ist nicht-aktivierend (`.nonactivatingPanel`), floating über
/// allen Apps und per Hintergrund-Drag verschiebbar. Es stiehlt nie den
/// Keyboard-Fokus — der Nutzer kann weiterschreiben, während die Pille läuft.
@MainActor
final class ReadingPillController {

    private let window: ReadingPillWindow
    private var hasPositioned = false

    init() {
        self.window = ReadingPillWindow()
    }

    func attach(progress: ReadingProgress, onStop: @escaping () -> Void) {
        let view = ReadingPillView(progress: progress, onStop: onStop)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 240, height: 44)
        window.contentView = hosting
        window.setContentSize(NSSize(width: 240, height: 44))
    }

    func show() {
        if !hasPositioned {
            positionAtBottomCenter()
            hasPositioned = true
        }
        window.alphaValue = 0
        window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            window.animator().alphaValue = 1
        }
    }

    func hide() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            self.window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            // Der completionHandler ist nicht als MainActor markiert; AppKit ruft
            // ihn in der Praxis auf dem Main-Thread, Swift 6 kann das aber nicht
            // beweisen. Expliziter Hop vermeidet die Isolations-Warnung.
            Task { @MainActor in
                self?.window.orderOut(nil)
            }
        })
    }

    private func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let x = visible.midX - size.width / 2
        let y = visible.minY + 56
        window.setFrame(NSRect(origin: CGPoint(x: x, y: y), size: size), display: true)
    }
}

/// Nicht-aktivierendes, randloses NSPanel für die Lesepille.
final class ReadingPillWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        isMovableByWindowBackground = true
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        alphaValue = 0
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
