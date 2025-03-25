import SwiftUI

struct AddItemView: View {
    var selectedChild: Child
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = "Chore"
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple.opacity(0.7))
                        .padding()
                }
            }

            Text("Vad vill du lägga till?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.purple)

            Picker("Välj typ", selection: $selectedTab) {
                Text("Syssla").tag("Chore")
                Text("Uppgift").tag("Task")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if selectedTab == "Chore" {
                AddChoreView(selectedChild: selectedChild)
            } else {
                AddTaskView(selectedChild: selectedChild)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}
