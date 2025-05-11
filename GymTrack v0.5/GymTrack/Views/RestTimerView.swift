import SwiftUI

// Simple Rest Timer View
struct RestTimerView: View {
    let duration: TimeInterval
    @State private var timeRemaining: TimeInterval
    @Environment(\.dismiss) private var dismiss
    // Use a Timer publisher
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(duration: TimeInterval) {
        self.duration = duration
        // Initialize the state variable correctly
        _timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Display formatted time
            Text(formatTime(timeRemaining))
                .font(.system(size: 70, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding()
            
            // Progress Ring (Optional but nice)
            ZStack {
                Circle()
                    .stroke(lineWidth: 15)
                    .opacity(0.2)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(timeRemaining / duration))
                    .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear(duration: 1.0), value: timeRemaining)
            }
            .frame(width: 200, height: 200)
            .padding(.bottom, 40)

            
            Button("Skip Rest") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            Spacer()
        }
        .padding()
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Optionally add sound/vibration here
                dismiss()
            }
        }
        .onDisappear {
            // Stop the timer when the view disappears
            timer.upstream.connect().cancel()
        }
    }
    
    // Helper to format time as MM:SS
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RestTimerView(duration: 90)
} 