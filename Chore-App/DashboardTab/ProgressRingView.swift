import SwiftUI

struct ProgressRingView: View {
    var progress: CGFloat
    var emoji: String
    var title: String
    var goalText: String
    var onEdit: () -> Void

    var body: some View {
        VStack {
            ZStack {
                ProgressRing(progress: progress)
                
                Text(emoji)
                    .font(.system(size: 40))
                    .scaleEffect(1.1)
            }

            Text(goalText)
                .font(.caption)
                .bold()
                .padding(.top, 4)

            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
            }
            .padding(.top, 2)

            Text(title)
                .font(.headline)
                .padding(.top, 4)
        }
        .frame(width: 140)
    }
}
