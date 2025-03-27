import SwiftUI


struct NavigationButton<Destination: View>: View {
    var title: String
    var destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
