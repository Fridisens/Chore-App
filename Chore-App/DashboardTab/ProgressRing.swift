import SwiftUI


struct ProgressRing: View {
    var progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .foregroundColor(Color.gray.opacity(0.2))

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.purple, Color.pink, Color.purple]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.purple.opacity(0.4), radius: 4, x: 0, y: 2)
                .animation(.easeOut(duration: 0.6), value: progress)
        }
        .frame(width: 130, height: 130)
    }
}
