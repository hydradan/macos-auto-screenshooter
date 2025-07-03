import Foundation
import SwiftUI
import AppKit
import Quartz
import UniformTypeIdentifiers

enum CaptureMode {
    case screen
    case window
    case customArea
}

class ScreenshotManager: ObservableObject {
    @Published var captureMode: CaptureMode = .screen
    @Published var selectedScreen: CGDirectDisplayID?
    @Published var selectedWindow: CGWindowID?
    @Published var customArea: CGRect?
    @Published var isCountingDown = false
    @Published var isCapturing = false
    @Published var captureProgress = 0
    
    private var screenshotCount = 20
    private var interval = 1000
    private var autoKeypress = true
    private var keypressInfo: KeypressInfo?
    private var savePath: String = ""
    
    func configure(count: Int, interval: Int, autoKeypress: Bool, keypressInfo: KeypressInfo?, savePath: String) {
        self.screenshotCount = count
        self.interval = interval
        self.autoKeypress = autoKeypress
        self.keypressInfo = keypressInfo
        self.savePath = savePath
    }
    
    func startCountdown() {
        NSApp.keyWindow?.makeFirstResponder(nil)
        DispatchQueue.main.async {
            self.isCountingDown = true
        }
    }
    
    func startCapture() {
        isCapturing = true
        isCountingDown = false
        captureProgress = 0
        
        createSaveDirectory()
        captureScreenshots()
    }
    
    private func createSaveDirectory() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: savePath) {
            try? fileManager.createDirectory(atPath: savePath, withIntermediateDirectories: true)
        }
    }
    
    private func captureScreenshots() {
        Task {
            for i in 0..<screenshotCount {
                await MainActor.run {
                    captureProgress = i + 1
                }
                
                takeScreenshot(index: i)
                
                if autoKeypress && i < screenshotCount - 1 {
                    pressKey()
                }
                
                if i < screenshotCount - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000)
                }
            }
            
            await MainActor.run {
                isCapturing = false
            }
        }
    }
    
    private func takeScreenshot(index: Int) {
        if captureMode == .window, let windowID = selectedWindow {
            activateWindow(windowID)
        }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let filename = "Screenshot \(timestamp) - \(index + 1).png"
        let effectiveSavePath = savePath.isEmpty ? NSHomeDirectory() + "/Pictures/AutoScreenshooter" : savePath
        let filePath = (effectiveSavePath as NSString).appendingPathComponent(filename)
        
        switch captureMode {
        case .screen:
            let displayID = selectedScreen ?? CGMainDisplayID()
            if let image = CGDisplayCreateImage(displayID) {
                saveImage(image, to: filePath)
            }
            
        case .window:
            if let windowID = selectedWindow {
                let option: CGWindowImageOption = [.boundsIgnoreFraming, .shouldBeOpaque]
                if let image = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, option) {
                    saveImage(image, to: filePath)
                }
            }
            
        case .customArea:
            let displayID = selectedScreen ?? CGMainDisplayID()
            if let rect = customArea, rect.width > 0, rect.height > 0 {
                if let image = CGDisplayCreateImage(displayID, rect: rect) {
                    saveImage(image, to: filePath)
                }
            }
        }
    }
    
    private func saveImage(_ cgImage: CGImage, to path: String) {
        let url = URL(fileURLWithPath: path)
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        
        if let destination = destination {
            CGImageDestinationAddImage(destination, cgImage, nil)
            CGImageDestinationFinalize(destination)
        }
    }
    
    private func pressKey() {
        guard let keypress = keypressInfo else { return }
        
        let source = CGEventSource(stateID: .hidSystemState)
        var flags = CGEventFlags(rawValue: 0)
        
        let flagMapping: [(NSEvent.ModifierFlags, CGEventFlags)] = [
            (.command, .maskCommand),
            (.option, .maskAlternate),
            (.control, .maskControl),
            (.shift, .maskShift)
        ]
        
        for (modifier, cgFlag) in flagMapping {
            if keypress.modifierFlags.contains(modifier) {
                flags.insert(cgFlag)
            }
        }
        
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keypress.keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }
        
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keypress.keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }
    
    private func activateWindow(_ windowID: CGWindowID) {
        if let windowList = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
           let windowInfo = windowList.first,
           let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32 {
            
            if let app = NSRunningApplication(processIdentifier: ownerPID) {
                app.activate(options: .activateIgnoringOtherApps)
                usleep(100000) // 100ms
            }
        }
    }
}
