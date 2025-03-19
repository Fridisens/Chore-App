import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AddTaskView: View {
    @State private var name = ""
    @State private var selectedStartTime = Date()
    @State private var selectedEndTime = Date()
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    @State private var selectedRepeatOption = "Aldrig"
    @State private var isAllDay = false
    @State private var taskType = "recurring"

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

                    Picker("Typ av uppgift", selection: $taskType) {
                        Text("Återkommande").tag("recurring")
                        Text("Engångsuppgift").tag("oneTime")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Heldag", isOn: $isAllDay)

                    DatePicker("Startdatum", selection: $selectedStartDate, displayedComponents: .date)
                    
                    if !isAllDay {
                        DatePicker("Starttid", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                            .onChange(of: selectedStartTime) { newStartTime in
                                let calendar = Calendar.current
                                if let newEndTime = calendar.date(byAdding: .hour, value: 1, to: newStartTime) {
                                    selectedEndTime = newEndTime
                                }
                            }

                        DatePicker("Sluttid", selection: $selectedEndTime, displayedComponents: .hourAndMinute)

                    }
                }

                if taskType == "recurring" {
                    Section(header: Text("Återkommande inställningar")) {
                        Picker("Upprepa", selection: $selectedRepeatOption) {
                            ForEach(repeatOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        DatePicker("Slutdatum", selection: $selectedEndDate, in: selectedStartDate..., displayedComponents: .date)
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
            startDate: selectedStartDate,
            endDate: taskType == "recurring" ? selectedEndDate : nil,
            isAllDay: isAllDay,
            type: taskType,
            repeatOption: taskType == "recurring" ? selectedRepeatOption : "Aldrig",
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
