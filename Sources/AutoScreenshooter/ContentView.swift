import SwiftUI
import AppKit
import Foundation

struct ContentView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @State private var screenshotCount = 10
    @State private var waitInterval = 500
    @State private var autoKeypress = true
    @State private var savePath = NSHomeDirectory() + "/Pictures/AutoScreenshooter"
    @State private var showingWindowPicker = false
    @State private var showingAreaSelector = false
    @State private var isCapturingKeypress = false
    @State private var selectionOverlay: SelectionOverlay?
    @State private var capturedKeypress: KeypressInfo? = KeypressInfo(
        keyCode: 0x31, // space key
        modifierFlags: [],
        characters: " ",
        displayComponents: ["Space"]
    )
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 30) {
                    // Header
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 15) {
                            if let url = Bundle.module.url(forResource: "autoshooter", withExtension: "png"),
                               let nsImg = NSImage(contentsOf: url) {
                                Image(nsImage: nsImg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Text("Auto Screenshooter")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    HStack {
                        HStack(spacing: 12) {
                            Text("Take")
                                .font(.title2)
                            
                            TextField("", value: $screenshotCount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                                .onChange(of: screenshotCount) { newValue in 
                                    if newValue <= 0 {
                                        screenshotCount = 1
                                    }
                                }
                            
                            Text("screenshots")
                                .font(.title2)
                        }
                        
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Automatically press")
                            
                            Button(action: {
                                if !isCapturingKeypress {
                                    startKeypressCapture()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if isCapturingKeypress {
                                        Text("Capturing")
                                            .foregroundColor(.blue)
                                    } else if let keypress = capturedKeypress {
                                        ForEach(keypress.displayComponents, id: \.self) { component in
                                            Text(component)
                                                .font(.system(size: 16, weight: .regular))
                                                
                                        }
                                    } else {
                                        Text("<None>")
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .background(isCapturingKeypress ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(4)
                            .disabled(!autoKeypress)
                            .opacity(autoKeypress ? 1 : 0.5)
                            
                            Text("after each screenshot")
                            .opacity(autoKeypress ? 1 : 0.5)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Toggle("", isOn: $autoKeypress)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle())
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .help("Click the button to capture a custom keypress")
                        }
                    }
                    HStack {
                        HStack(spacing: 8) {
                            Text("Wait")
                            
                            TextField("", value: $waitInterval, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                                .onChange(of: waitInterval) { newValue in
                                    if newValue <= 0 {
                                        waitInterval = 500
                                    }
                                }
                            
                            Text("ms after each screenshot")
                        }
                        
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        Text("Save captured images to")
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            TextField("", text: $savePath)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 200)
                                .disabled(true)
                            
                            Button("Browse...") {
                                selectSaveDirectory()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    HStack(spacing: 20) {
                        Button(action: selectScreen) {
                            Label("Select screen", systemImage: "rectangle.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Button(action: selectCustomArea) {
                            Label("Custom Area", systemImage: "crop")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 10)
                }
                .padding(40)
                
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            if showingAreaSelector {
                CustomAreaOverlay(isPresented: $showingAreaSelector)
            }
            
            if screenshotManager.isCountingDown {
                CountdownView(
                    isPresented: $screenshotManager.isCountingDown,
                    onComplete: {
                        defocus()
                        screenshotManager.startCapture()
                    },
                    onCancel: { screenshotManager.isCountingDown = false }
                )
                
            }
            
        }
        .frame(width: 600)
        .sheet(isPresented: $showingWindowPicker) {
            WindowPickerView(isPresented: $showingWindowPicker)
        }
        .onChange(of: showingAreaSelector) { newValue in
            if !newValue, screenshotManager.customArea != nil {
                screenshotManager.startCountdown()
            }
        }
    }

    func startKeypressCapture() {
        isCapturingKeypress = true
        
        // Create a local monitor to capture key presses
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.isCapturingKeypress {
                self.capturedKeypress = KeypressInfo(
                    keyCode: event.keyCode,
                    modifierFlags: event.modifierFlags,
                    characters: event.charactersIgnoringModifiers ?? ""
                )
                self.isCapturingKeypress = false
                return nil
            }
            return event
        }
    }
    
    func selectScreen() {
        configureScreenshotManager()
        showingWindowPicker = true
    }
    
    func selectCustomArea() {
        configureScreenshotManager()
        screenshotManager.captureMode = .customArea
        selectionOverlay = SelectionOverlay()
        selectionOverlay?.begin { rect in
            screenshotManager.customArea = rect
            selectionOverlay = nil
            if rect != nil {
                screenshotManager.startCountdown()
            }
        }
    }
    
    private func configureScreenshotManager() {
        if screenshotCount <= 0 { screenshotCount = 10 }
        if waitInterval <= 0 { waitInterval = 500 }
        
        screenshotManager.configure(
            count: screenshotCount,
            interval: waitInterval,
            autoKeypress: autoKeypress,
            keypressInfo: capturedKeypress,
            savePath: savePath
        )
    }
    
    private func defocus() {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
    

    
    func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select Save Location"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                savePath = url.path
            }
        }
    }
}
