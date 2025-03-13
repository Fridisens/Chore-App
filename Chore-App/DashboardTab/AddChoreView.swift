// forms for adding chores and tasks that you then can find at profile page

import SwiftUI
import Firebase
import FirebaseAuth

struct AddChoreView: View {
    @State private var name = ""
    @State private var value: Int = 0
    @State private var selectedRewardType: String = "money"
    @State private var selectedDays: [String] = []
    
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    var selectedChild: Child
    
    let weekdays = ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Syssla")) {
                    TextField("Namn på sysslan", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Belöning")) {
                    Stepper("Värde: \(value) \(selectedRewardType == "money" ? "SEK" : "min")", value: $value, in: 1...100)
                    
                    HStack {
                        Button(action: { selectedRewardType = "money" }) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(selectedRewardType == "money" ? .purple : .gray)
                                .font(.largeTitle)
                        }
                        
                        Button(action: { selectedRewardType = "screenTime" }) {
                            Image(systemName: "tv.fill")
                                .foregroundColor(selectedRewardType == "screenTime" ? .purple : .gray)
                                .font(.largeTitle)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                
                Section(header: Text("Välj dagar")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(weekdays, id: \.self) { day in
                            Button(action: {
                                if selectedDays.contains(day) {
                                    selectedDays.removeAll { $0 == day }  // Ta bort vald dag
                                } else {
                                    selectedDays.append(day)  // Lägg till vald dag
                                }
                            }) {
                                Text(String(day.prefix(1)))  // Visa endast första bokstaven
                                    .font(.headline)
                                    .frame(width: 40, height: 40)  // Storlek på varje knapp
                                    .background(
                                        selectedDays.contains(day) ? Color.purple : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10)) // Runda hörn på varje knapp
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(selectedDays.contains(day) ? 0 : 1), lineWidth: 1) // Synlig kant för icke valda
                                    )
                            }
                            .buttonStyle(.plain) // Tar bort SwiftUIs standardknapp-styling
                        }
                    }
                    .padding(.vertical, 5)
                }
                    
                    Section {
                        Button(action: saveChore) {
                            Text("Spara Syssla")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(name.isEmpty ? Color.gray.opacity(0.5) : Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(name.isEmpty)
                    }
                }
                .navigationTitle("Lägg till Syssla")
            }
        }
    
        
        private func saveChore() {
            guard let userId = authService.user?.id else { return }
            
            let newChore = Chore(
                id: UUID().uuidString,
                name: name,
                value: value,
                completed: 0,
                assignedBy: userId,
                rewardType: selectedRewardType,
                days: selectedDays
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
    

