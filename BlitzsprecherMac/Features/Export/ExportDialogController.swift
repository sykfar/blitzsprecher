import AppKit
import SwiftUI

/// Zeigt den Ablage-Dialog in einem eigenen NSWindow. Kein nicht-aktivierendes
/// Panel wie die Lesepille — der Nutzer soll den Dialog ja aktiv bedienen.
@MainActor
final class ExportDialogController {

    private var window: NSWindow?

    func present(result: ExportResult,
                 vault: VaultStorage,
                 commit: @escaping (ExportCommitOptions) -> Void,
                 cancel: @escaping () -> Void) {
        close()

        let view = ExportDialogView(
            result: result,
            vault: vault,
            onCommit: { [weak self] options in
                commit(options)
                self?.close()
            },
            onCancel: { [weak self] in
                cancel()
                self?.close()
            }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 560, height: 500)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Hörfassung ablegen"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = hosting
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }
}
