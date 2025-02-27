// forms for adding chores and tasks that you then can find at profile page

import SwiftUI
import Firebase
import FirebaseAuth

struct AddChoreView: View {
    var selectedChild: Child
    @State private var name = ""
    @State private var description = ""
    @State private var value: Int = 0
    @State private var frequency = "Daily"
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Add Chore for \(selectedChild.name)")
                .font(.title2)
                .padding()
            
            TextField("Chore name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()
            
            
            TextField("Value (SEK)", value: $value, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Picker("Frequency", selection: $frequency) {
                Text("Daily").tag("Daily")
                Text("Weekly").tag("Weekly")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button("Save Chore") {
                saveChore()
            }
            .padding()
            .disabled(name.isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    private func saveChore() {
        guard let parentId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let choreRef = db.collection("users").document(parentId).collection("children").document(selectedChild.id).collection("chores").document()
        
        let newChore = Chore(id: choreRef.documentID, name: name, value: value, frequency: frequency == "Daily" ? 1 : 7, completed: 0, assignedBy: parentId)
        
        do {
            try choreRef.setData(from: newChore) { error in
                if let error = error {
                    print("Error adding chore: \(error.localizedDescription)")
                } else {
                    print("Chore saved successfully with value \(value) SEK!")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            print("Error encoding chore: \(error.localizedDescription)")
        }
    }
}
