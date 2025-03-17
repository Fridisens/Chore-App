//forms for adding task that you then can find at profile page
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AddTaskView: View {
    @State private var name = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: [String] = []
    
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    var selectedChild: Child
    
    let weekdays = ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Uppgift")) {
                    TextField("Namn på uppgiften", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    DatePicker("Tid", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                }
                
                Section(header: Text("Välj dagar")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(weekdays, id: \.self) { day in
                            Button(action: {
                                if let index = selectedDays.firstIndex(of: day) {
                                    selectedDays.remove(at: index)  // ❌ Ta bort om vald
                                } else {
                                    selectedDays.append(day)  // ✅ Lägg till om inte vald
                                }
                            }) {
                                Text(String(day.prefix(1)))
                                    .font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(selectedDays.contains(day) ? Color.purple : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(selectedDays.contains(day) ? 0 : 1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section {
                    Button(action: saveTask) {
                        Text("Spara Uppgift")
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
            .navigationTitle("Lägg till Uppgift")
        }
    }
    
    private func saveTask() {
        guard let userId = authService.user?.id else { return }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let formattedTime = formatter.string(from: selectedTime)
        
        let newTask = Task(
            id: UUID().uuidString,
            name: name,
            time: formattedTime,
            days: selectedDays,
            completed: 0,
            assignedBy: userId
        )
        
        firestoreService.addTask(for: userId, childId: selectedChild.id, task: newTask) { result in
            switch result {
            case .success():
                print("✅ Uppgift tillagd!")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("❌ Fel vid tillägg av uppgift: \(error.localizedDescription)")
            }
        }
    }
}
