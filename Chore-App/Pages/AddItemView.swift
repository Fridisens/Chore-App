import SwiftUI



struct AddItemView: View {
    var selectedChild: Child
    
    @State private var selectedTab = "Chore"
    
    var body: some View {
        VStack {
            Text("Lägg till syssla eller uppgift för \(selectedChild.name)")
                .font(.largeTitle)
                .padding()
            
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
