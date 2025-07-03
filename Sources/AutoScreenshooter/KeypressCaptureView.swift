import SwiftUI
import AppKit

struct KeypressCaptureView: View {
    @Binding var isPresented: Bool
    @Binding var capturedKeypress: KeypressInfo?
    @State private var isCapturing = false
    @State private var currentKeypress: KeypressInfo?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Keypress Capture")
                .font(.title2)
                .fontWeight(.bold)
            
            if isCapturing {
                VStack(spacing: 10) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Press any key combination...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 150)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            } else if let keypress = currentKeypress {
                VStack(spacing: 10) {
                    HStack(spacing: 5) {
                        ForEach(keypress.displayComponents, id: \.self) { component in
                            Text(component)
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    
                    Text("Key Code: \(keypress.keyCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 150)
            } else {
                VStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Click 'Start Capture' to record a keypress")
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 150)
            }
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                
                if !isCapturing {
                    Button("Start Capture") {
                        startCapture()
                    }
                    
                    if currentKeypress != nil {
                        Button("Use This Keypress") {
                            capturedKeypress = currentKeypress
                            isPresented = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button("Stop Capture") {
                        stopCapture()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(30)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
    
    func startCapture() {
        isCapturing = true
        currentKeypress = nil
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.isCapturing {
                self.currentKeypress = KeypressInfo(
                    keyCode: event.keyCode,
                    modifierFlags: event.modifierFlags,
                    characters: event.charactersIgnoringModifiers ?? ""
                )
                self.stopCapture()
                return nil
            }
            return event
        }
    }
    
    func stopCapture() {
        isCapturing = false
    }
}

struct KeypressInfo: Equatable {
    let keyCode: UInt16
    let modifierFlags: NSEvent.ModifierFlags
    let characters: String
    let customDisplayComponents: [String]?
    
    init(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags, characters: String, displayComponents: [String]? = nil) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.characters = characters
        self.customDisplayComponents = displayComponents
    }
    
    var displayComponents: [String] {
        if let customComponents = customDisplayComponents {
            return customComponents
        }
        
        var components: [String] = []
        
        if modifierFlags.contains(.command) {
            components.append("⌘")
        }
        if modifierFlags.contains(.option) {
            components.append("⌥")
        }
        if modifierFlags.contains(.control) {
            components.append("⌃")
        }
        if modifierFlags.contains(.shift) {
            components.append("⇧")
        }
        
        let specialKeyMap: [UInt16: String] = [
            36: "↩",   // Return
            48: "⇥",   // Tab
            49: "Space",
            51: "⌫",   // Delete
            53: "⎋",   // Escape
            123: "←",  // Left arrow
            124: "→",  // Right arrow
            125: "↓",  // Down arrow
            126: "↑"   // Up arrow
        ]
        
        if let symbol = specialKeyMap[keyCode] {
            components.append(symbol)
        } else if !characters.isEmpty {
            components.append(characters.uppercased())
        } else {
            components.append("Key \(keyCode)")
        }
        
        return components
    }
    
    var displayString: String {
        displayComponents.joined(separator: " + ")
    }
}
