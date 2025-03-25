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
    @State private var selectedIcon: String = "star.fill"
    
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    var selectedChild: Child
    let repeatOptions = ["Aldrig", "Dagligen", "Varje vecka", "Varje månad", "Varje år"]
    let availableIcons = ["star.fill", "leaf.fill", "house.fill", "gamecontroller.fill", "flame.fill", "heart.fill", "magazine.fill", "sparkles", "bolt.fill", "camera.fill", "paintbrush.fill", "hammer.fill", "shower.fill", "washer.fill", "car.fill","dog.fill", "cat.fill", "party.popper.fill"]

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.purple)

                    TextField("Namn på uppgiften", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Picker("Typ av uppgift", selection: $taskType) {
                        Text("Återkommande").tag("recurring")
                        Text("Engångsuppgift").tag("oneTime")
                    }
                    
                    Section(header: Text("")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 30))
                                            .padding()
                                            .background(selectedIcon == icon ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == icon ? Color.purple : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top, 5)
                    
                    Toggle("Heldag", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    
                    DatePicker("Startdatum", selection: $selectedStartDate, displayedComponents: .date)
                        .accentColor(.purple)
                    
                    if !isAllDay {
                        DatePicker("Starttid", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                            .accentColor(.purple)
                            .onChange(of: selectedStartTime) {
                                let calendar = Calendar.current
                                if let newEndTime = calendar.date(byAdding: .hour, value: 1, to: selectedStartTime) {
                                    selectedEndTime = newEndTime
                                }
                            }
                        
                        DatePicker("Sluttid", selection: $selectedEndTime, displayedComponents: .hourAndMinute)
                            .accentColor(.purple)
                    }
                    
                    if taskType == "recurring" {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Återkommande inställningar")
                                .font(.headline)
                                .foregroundColor(.purple)
                            
                            Picker("Upprepa", selection: $selectedRepeatOption) {
                                ForEach(repeatOptions, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            DatePicker("Slutdatum", selection: $selectedEndDate, in: selectedStartDate..., displayedComponents: .date)
                                .accentColor(.purple)
                        }
                    }

                    Button(action: saveTask) {
                        Text("Spara Uppgift")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty ? Color.gray.opacity(0.5) : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(name.isEmpty)
                    .padding(.top)
                }
                .padding()
            }
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
            date: taskType == "oneTime" ? selectedStartDate : nil,
            type: taskType,
            repeatOption: selectedRepeatOption,
            completed: 0,
            assignedBy: userId,
            icon: selectedIcon
        )
        
        firestoreService.addTask(for: userId, childId: selectedChild.id, task: newTask) { result in
            switch result {
            case .success:
                print("Uppgift tillagd!")
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Fel vid tillägg av uppgift: \(error.localizedDescription)")
            }
        }
    }
}
