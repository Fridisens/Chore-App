import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AddTaskView: View {
    @State private var name = ""
    @State private var selectedStartTime = Date()
    @State private var selectedEndTime = Date()
    @State private var isAllDay = false
    @State private var taskType = "recurring"
    @State private var selectedDate = Date()
    @State private var startDate = Date()
    @State private var repeatOption = "Aldrig"
    
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    var selectedChild: Child
    let repeatOptions = ["Aldrig", "Dagligen", "Varje vecka", "Varje månad", "Varje år"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Uppgift")) {
                    TextField("Namn på uppgiften", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                    
                    Picker("Typ av uppgift", selection: $taskType) {
                        Text("Återkommande").tag("recurring")
                        Text("Engångsuppgift").tag("oneTime")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Heldag", isOn: $isAllDay)
                    
                    if taskType == "oneTime" {
                        DatePicker("Datum", selection: $selectedDate, displayedComponents: .date)
                    }
                    
                    if taskType == "recurring" {
                        DatePicker("Startdatum", selection: $startDate, displayedComponents: .date)
                        
                        Picker("Upprepa", selection: $repeatOption) {
                            ForEach(repeatOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    if !isAllDay {
                        DatePicker("Starttid", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                        DatePicker("Sluttid", selection: $selectedEndTime, displayedComponents: .hourAndMinute)
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

        let newTask = Task(
            id: UUID().uuidString,
            name: name,
            startTime: isAllDay ? nil : selectedStartTime,
            endTime: isAllDay ? nil : selectedEndTime,
            isAllDay: isAllDay,
            startDate: taskType == "recurring" ? startDate : nil,
            date: taskType == "oneTime" ? selectedDate : nil,
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
