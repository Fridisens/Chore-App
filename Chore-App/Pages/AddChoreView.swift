// forms for adding chores and tasks that you then can find at profile page

import SwiftUI
import Firebase
import FirebaseAuth

struct AddChoreView: View {
    var selectedChild: Child
    @EnvironmentObject var authService: AuthService
    @State private var name = ""
    @State private var description = ""
    @State private var value: Int = 0
    @State private var frequency = "Daily"
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Lägg till syssla för \(selectedChild.name)")
                .font(.title2)
                .padding()
            
            TextField("Syssla", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()
            
            
            TextField("Saldo (SEK)", value: $value, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Picker("Hur ofta?", selection: $frequency) {
                Text("Dagligen").tag("Daily")
                Text("Veckovis").tag("Weekly")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button("Spara") {
                saveChore()
            }
            .padding()
            .disabled(name.isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    private func saveChore() {
            guard let userId = authService.user?.id else { return }
            
            let newChore = Chore(
                id: UUID().uuidString,
                name: name,
                value: value,
                frequency: frequency == "Daily" ? 1 : 7,
                completed: 0,
                assignedBy: userId
            )
            
            firestoreService.addChore(for: userId, childId: selectedChild.id, chore: newChore) { result in
                switch result {
                case .success():
                    print("Syssla tillagd!")
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Fel vid tillägg av syssla: \(error.localizedDescription)")
                }
            }
        }
    }
