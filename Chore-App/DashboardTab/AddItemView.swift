import SwiftUI



struct AddItemView: View {
    var selectedChild: Child
    
    @State private var selectedTab = "Chore"
    
    var body: some View {
        VStack {
            Picker(selection: $selectedTab, label: Text("Välj typ")) {
                Text("Syssla").tag("Chore")
                Text("Uppgift").tag("Task")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == "Chore" {
                AddChoreView(selectedChild: selectedChild)
            } else {
                AddTaskView(selectedChild: selectedChild)
            }
        }
        .padding()
    }
}
