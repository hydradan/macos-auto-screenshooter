import SwiftUI
import AppKit

struct WindowPickerView: View {
    @Binding var isPresented: Bool
    @State private var selectedTab = 0
    @State private var windows: [WindowInfo] = []
    @State private var screens: [ScreenInfo] = []
    @State private var windowThumbnails: [CGWindowID: NSImage] = [:]
    @State private var screenThumbnails: [CGDirectDisplayID: NSImage] = [:]
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                
                Picker("", selection: $selectedTab) {
                    Text("Screens").tag(0)
                    Text("Windows").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 20) {
                    if selectedTab == 0 {
                        ForEach(screens) { screen in
                            ScreenThumbnail(
                                screen: screen,
                                thumbnail: screenThumbnails[screen.displayID],
                                isSelected: screenshotManager.selectedScreen == screen.displayID
                            ) {
                                screenshotManager.selectedScreen = screen.displayID
                                screenshotManager.selectedWindow = nil
                                screenshotManager.captureMode = .screen
                            }
                        }
                    } else {
                        ForEach(windows) { window in
                            WindowThumbnail(
                                window: window,
                                thumbnail: windowThumbnails[window.windowID],
                                isSelected: screenshotManager.selectedWindow == window.windowID,
                                action: {
                                    screenshotManager.selectedWindow = window.windowID
                                    screenshotManager.selectedScreen = nil
                                    screenshotManager.captureMode = .window
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            
            Button("Start Capture") {
                startCapture()
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(!isSelectionValid())
        }
        .frame(width: 800, height: 600)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 20)
        .onAppear {
            loadWindowsAndScreens()
        }
    }
    
    func loadWindowsAndScreens() {
        screens = NSScreen.screens.enumerated().map { index, screen in
            ScreenInfo(
                displayID: screen.displayID,
                name: "Display \(index + 1)",
                frame: screen.frame
            )
        }
        
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            windows = windowList.compactMap { windowInfo in
                guard let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                      let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                      let alpha = windowInfo[kCGWindowAlpha as String] as? Double,
                      let layer = windowInfo[kCGWindowLayer as String] as? Int,
                      let bounds = windowInfo[kCGWindowBounds as String] as? [String: Double],
                      let height = bounds["Height"], let width = bounds["Width"],
                      alpha >= 0.1,
                      layer <= 25,
                      height >= 60,
                      width >= 60
                else { return nil }
                
                let systemAppsToExclude = ["Window Server", "Dock", "SystemUIServer", "Control Center",
                                         "Notification Center", "Screenshot", "ScreenFloat", "coreautha", "loginwindow"]
                
                if systemAppsToExclude.contains(ownerName) { return nil }
                
                let windowName = windowInfo[kCGWindowName as String] as? String ?? "Untitled"
                
                return WindowInfo(
                    windowID: windowID,
                    ownerName: ownerName,
                    windowName: windowName,
                    bounds: CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0,
                                   width: width, height: height)
                )
            }
        }
        
        // Generate thumbnails after loading windows and screens
        Task {
            await generateThumbnails()
        }
    }
    
    private func generateThumbnails() async {
        // Generate window thumbnails
        for window in windows {
            if let image = generateWindowThumbnail(for: window.windowID) {
                await MainActor.run {
                    windowThumbnails[window.windowID] = image
                }
            }
        }
        
        // Generate screen thumbnails
        for screen in screens {
            if let image = generateScreenThumbnail(for: screen.displayID) {
                await MainActor.run {
                    screenThumbnails[screen.displayID] = image
                }
            }
        }
    }
    
    private func generateWindowThumbnail(for windowID: CGWindowID) -> NSImage? {
        let options: CGWindowImageOption = [.boundsIgnoreFraming, .nominalResolution]
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            options
        ) else { return nil }
        
        return NSImage(cgImage: cgImage, size: .zero)
    }
    
    private func generateScreenThumbnail(for displayID: CGDirectDisplayID) -> NSImage? {
        guard let cgImage = CGDisplayCreateImage(displayID) else { return nil }
        return NSImage(cgImage: cgImage, size: .zero)
    }
    
    private func isSelectionValid() -> Bool {
        if selectedTab == 0 {
            return screenshotManager.selectedScreen != nil
        } else {
            return screenshotManager.selectedWindow != nil
        }
    }
    
    func startCapture() {
        guard isSelectionValid() else { return }
        isPresented = false
        
        // Ensure we have a valid selection
        if selectedTab == 0 {
            if screenshotManager.selectedScreen == nil {
                screenshotManager.selectedScreen = screens.first?.displayID ?? CGMainDisplayID()
            }
            screenshotManager.captureMode = .screen
        } else {
            screenshotManager.captureMode = .window
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            screenshotManager.startCountdown()
        }
    }
}

struct ScreenThumbnail: View {
    let screen: ScreenInfo
    let thumbnail: NSImage?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            Image(systemName: "display")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
                
                Text(screen.name)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .background(Color(NSColor.windowBackgroundColor))
                                    .clipShape(Circle())
                                    .offset(x: -8, y: 8),
                                alignment: .topTrailing
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

struct WindowThumbnail: View {
    let window: WindowInfo
    let thumbnail: NSImage?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            VStack {
                                Image(systemName: "macwindow")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text(window.ownerName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(window.windowName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(window.ownerName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .background(Color(NSColor.windowBackgroundColor))
                                    .clipShape(Circle())
                                    .offset(x: -8, y: 8),
                                alignment: .topTrailing
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .help("\(window.ownerName): \(window.windowName)")
    }
}

struct ScreenInfo: Identifiable {
    let id = UUID()
    let displayID: CGDirectDisplayID
    let name: String
    let frame: CGRect
}

struct WindowInfo: Identifiable {
    let id = UUID()
    let windowID: CGWindowID
    let ownerName: String
    let windowName: String
    let bounds: CGRect
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID ?? 0
    }
}
