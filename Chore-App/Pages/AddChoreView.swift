// forms for adding chores and tasks that you then can find at profile page

import SwiftUI


struct AddChoreView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var value = 0.0
    @State private var frequency: String = "Daily"
    @State private var isComplete = false
    
    
    var body: some View {
        VStack {
          
            
            TextField("Chore name", text: $name )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()
            
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()
            
            
        }
    }
    
    
}
