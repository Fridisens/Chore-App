import SwiftUI
import Firebase
import FirebaseAuth

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var tasks: [Task] = []
    @StateObject private var firestoreService = FirestoreService()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            Text("Kalender")
                .font(.largeTitle)
                .foregroundColor(.purple)
                .padding()
            
            DatePicker("Välj datum", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .accentColor(.purple)
                .padding()
                .onChange(of: selectedDate) {
                    fetchTasksForSelectedDate()
                }
            
            if tasks.isEmpty {
                Text("Inga uppgifter för denna dag")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(tasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.name)
                                .font(.headline)
                            
                            if task.isAllDay {
                                Text("Heldag")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                if let startTime = task.startTime, let endTime = task.endTime {
                                    Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                        
                        if task.completed > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(5)
                }
            }
        }
        .onAppear {
            fetchTasksForSelectedDate()
        }
    }
    
    private func fetchTasksForSelectedDate() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("children").getDocuments { (snapshot, error) in
            if let error = error {
                print("Fel vid hämtning av barn: \(error.localizedDescription)")
                return
            }
            
            let children = snapshot?.documents.compactMap { $0.documentID } ?? []
            var allTasks: [Task] = []
            
            let group = DispatchGroup()
            
            for childId in children {
                group.enter()
                db.collection("users").document(userId).collection("children").document(childId).collection("tasks").getDocuments { snapshot, error in
                    if let error = error {
                        print("Fel vid hämtning av uppgifter: \(error.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    let fetchedTasks = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Task.self)
                    } ?? []
                    
                    allTasks.append(contentsOf: fetchedTasks)
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.tasks = self.filterTasks(for: self.selectedDate, allTasks: allTasks)
            }
        }
    }
    
    private func filterTasks(for date: Date, allTasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let selectedDay = calendar.component(.weekday, from: date)
        
        return allTasks.filter { task in
            if let taskDate = task.date, task.type == "oneTime" {
                return Calendar.current.isDate(taskDate, inSameDayAs: date)
            } else if task.type == "recurring", let startDate = task.startDate {
                return startDate <= date && shouldRepeat(task: task, selectedDate: date)
            }
            return false
        }
    }

    private func shouldRepeat(task: Task, selectedDate: Date) -> Bool {
        guard let startDate = task.startDate else { return false }
        
        let calendar = Calendar.current
        switch task.repeatOption {
        case "Dagligen":
            return true
        case "Varje vecka":
            return calendar.component(.weekday, from: startDate) == calendar.component(.weekday, from: selectedDate)
        case "Varje månad":
            return calendar.component(.day, from: startDate) == calendar.component(.day, from: selectedDate)
        case "Varje år":
            return calendar.component(.month, from: startDate) == calendar.component(.month, from: selectedDate) &&
                   calendar.component(.day, from: startDate) == calendar.component(.day, from: selectedDate)
        default:
            return false
        }
    }


    private func getWeekdayString(_ weekday: Int) -> String {
        let weekdays = ["Sön", "Mån", "Tis", "Ons", "Tors", "Fre", "Lör"]
        return weekdays[(weekday - 1) % 7]
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
