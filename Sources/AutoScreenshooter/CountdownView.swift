import SwiftUI
import AppKit

struct CountdownView: View {
    @Binding var isPresented: Bool
    @State private var countdown = 3
    let onComplete: () -> Void
    let onCancel: () -> Void
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var eventMonitor: Any? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Get Ready!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .scaleEffect(countdown == 0 ? 1.5 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: countdown)
                
                Text("Position your screen for capture")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                Button("Cancel Capture", role: .cancel) {
                    cancelCountdown()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
            }
            .padding(50)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .shadow(radius: 20)
            )
        }
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.upstream.connect().cancel()
                isPresented = false
                onComplete()
            }
        }
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC
                    cancelCountdown()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
    
    private func cancelCountdown() {
        timer.upstream.connect().cancel()
        isPresented = false
        onCancel()
    }
}
