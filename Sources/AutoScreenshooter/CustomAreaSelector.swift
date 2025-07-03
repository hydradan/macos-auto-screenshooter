import SwiftUI
import AppKit

struct CustomAreaSelector: NSViewRepresentable {
    @Binding var selectedArea: CGRect?
    @Binding var isSelecting: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = SelectionView()
        view.onSelectionComplete = { rect in
            selectedArea = rect
            isSelecting = false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class SelectionView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var selectionLayer: CALayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        
        let layer = CALayer()
        layer.borderColor = NSColor.systemBlue.cgColor
        layer.borderWidth = 2
        layer.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
        self.layer?.addSublayer(layer)
        selectionLayer = layer
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentPoint = point
        updateSelection()
    }
    
    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        updateSelection()
    }
    
    override func mouseUp(with event: NSEvent) {
        if let start = startPoint, let current = currentPoint {
            let rect = CGRect(
                x: min(start.x, current.x),
                y: min(start.y, current.y),
                width: abs(current.x - start.x),
                height: abs(current.y - start.y)
            )
            
            let screenRect = window?.convertToScreen(convert(rect, to: nil)) ?? rect
            onSelectionComplete?(screenRect)
        }
    }
    
    private func updateSelection() {
        guard let start = startPoint, let current = currentPoint else { return }
        
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        selectionLayer?.frame = rect
        CATransaction.commit()
    }
}

struct CustomAreaOverlay: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Click & drag to select.")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Press Esc to cancel.")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.7))
                
                Spacer()
            }
            
            CustomAreaSelector(
                selectedArea: $screenshotManager.customArea,
                isSelecting: $isPresented
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC
                    isPresented = false
                    return nil
                }
                return event
            }
        }
    }
}
