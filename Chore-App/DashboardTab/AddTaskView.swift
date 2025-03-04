//forms for adding task that you then can find at profile page
import SwiftUI

struct AddTaskView: View {
    var selectedChild: Child

    var body: some View {
        VStack {
            Text("Lägg till uppgift för \(selectedChild.name)")
                .font(.largeTitle)
                .padding()
        }
    }
}
