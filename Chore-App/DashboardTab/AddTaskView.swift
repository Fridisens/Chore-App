import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AddTaskView: View {
    @State private var name = ""
    @State private var selectedTime = Date()
    @State private var selectedEndTime = Date()
    @State private var selectedDays: [String] = []
    @State private var isAllDay = false
    @State private var taskType = "recurring" // "oneTime" eller "recurring"
    @State private var selectedDate = Date()
    @State private var repeatOption = "Aldrig" // Upprepning: Aldrig, Dagligen, Varje vecka, Varje månad, Varje år
    
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    var selectedChild: Child
    let weekdays = ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]
    let repeatOptions = ["Aldrig", "Dagligen", "Varje vecka", "Varje månad", "Varje år"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Uppgift")) {
                    TextField("Namn på uppgiften", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    Picker("Typ av uppgift", selection: $taskType) {
                        Text("Återkommande").tag("recurring")
                        Text("Engångsuppgift").tag("oneTime")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Heldag", isOn: $isAllDay)
                    
                    if taskType == "oneTime" {
                        DatePicker("Datum", selection: $selectedDate, displayedComponents: .date)
                    }
                    
                    if !isAllDay {
                        DatePicker("Starttid", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        DatePicker("Sluttid", selection: $selectedEndTime, displayedComponents: .hourAndMinute)
                    }
                }

                if taskType == "recurring" {
                    Section(header: Text("Välj dagar")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                            ForEach(weekdays, id: \.self) { day in
                                Button(action: {
                                    if let index = selectedDays.firstIndex(of: day) {
                                        selectedDays.remove(at: index)
                                    } else {
                                        selectedDays.append(day)
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
                        
                        Picker("Upprepa", selection: $repeatOption) {
                            ForEach(repeatOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
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
        let formattedEndTime = formatter.string(from: selectedEndTime)
        let formattedDate = DateFormatter.localizedString(from: selectedDate, dateStyle: .short, timeStyle: .none)

        let newTask = Task(
            id: UUID().uuidString,
            name: name,
            time: isAllDay ? "Heldag" : formattedTime,
            duration: isAllDay ? nil : Calendar.current.dateComponents([.minute], from: selectedTime, to: selectedEndTime).minute,
            date: taskType == "oneTime" ? formattedDate : nil,
            days: taskType == "recurring" ? selectedDays : [],
            type: taskType,
            repeatOption: taskType == "recurring" ? repeatOption : "Aldrig",
            completed: 0,
            assignedBy: userId
        )

        firestoreService.addTask(for: userId, childId: selectedChild.id, task: newTask) { result in
            switch result {
            case .success():
                print("Uppgift tillagd!")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Fel vid tillägg av uppgift: \(error.localizedDescription)")
            }
        }
    }
}
