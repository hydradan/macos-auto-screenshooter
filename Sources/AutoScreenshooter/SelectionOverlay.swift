import SwiftUI
import AppKit

final class SelectionOverlay {
    private var windows: [NSWindow] = []
    private var escapeMonitor: Any?
    func begin(completion: @escaping (CGRect?) -> Void) {
        for screen in NSScreen.screens {
            let win = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            win.level = .statusBar
            win.isOpaque = false
            win.backgroundColor = .clear
            win.ignoresMouseEvents = false
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let content = SelectionView(frame: screen.frame)
            content.onSelectionComplete = { [weak self] rect in
                self?.end()
                completion(rect)
            }
            win.contentView = content
            win.makeKeyAndOrderFront(nil)
            windows.append(win)
        }

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.end()
                completion(nil)
                return nil
            }
            return event
        }
    }
    func end() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }
}
