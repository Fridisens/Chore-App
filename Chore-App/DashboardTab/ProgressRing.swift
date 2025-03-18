import SwiftUI

struct ProgressRing: View {
    var progress: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(Color.gray)
            
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(progress >= 1.0 ? Color.green : Color.purple)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut, value: progress)
        }
    }
}
