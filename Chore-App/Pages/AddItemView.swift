import SwiftUI



struct AddItemView: View {
    @State private var selectedTab = "Chore"
    
    var body: some View {
        VStack {
            Text("Add Chore or Task")
                .font(.largeTitle)
                .padding()
            
            
            Picker(selection: $selectedTab, label: Text("Selected Type")) {
                Text("Chore").tag("Chore")
                Text("Task").tag("Task")
            }
            
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == "Chore" {
                AddChoreView()
            } else {
                AddTaskView()
            }
        }
        
        .padding()
    }
}
