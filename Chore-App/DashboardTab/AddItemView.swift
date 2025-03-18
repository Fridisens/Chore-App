import SwiftUI

struct AddItemView: View {
    var selectedChild: Child
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = "Chore"
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Text("Vad vill du lägga till?")
                .font(.headline)
                .padding(.top)
            
            Picker(selection: $selectedTab, label: Text("Välj typ")) {
                Text("Syssla").tag("Chore")
                Text("Uppgift").tag("Task")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if selectedTab == "Chore" {
                AddChoreView(selectedChild: selectedChild)
            } else {
                AddTaskView(selectedChild: selectedChild)
            }
        }
        .padding()
    }
}
