import SwiftUI
import AppKit

@main
struct AutoScreenshooterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var screenshotManager = ScreenshotManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenshotManager)
                .frame(minWidth: 600, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        requestScreenCaptureAccess()
    }
    
    func requestScreenCaptureAccess() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)
        _ = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
    }
}
