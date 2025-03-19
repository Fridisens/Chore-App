import SwiftUI
import Firebase
import FirebaseAuth

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var tasks: [Task] = []
    @State private var taskDates: Set<Date> = []
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
                .overlay(alignment: .bottom) {
                    if taskDates.contains(selectedDate) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                            .offset(y: 20)
                    }
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
            fetchAllTaskDates()
            fetchTasksForSelectedDate()
        }
    }

    private func fetchAllTaskDates() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("children").getDocuments { (snapshot, error) in
            if let error = error {
                print("Fel vid hämtning av barn: \(error.localizedDescription)")
                return
            }

            let children = snapshot?.documents.compactMap { $0.documentID } ?? []
            var allTaskDates: Set<Date> = []
            let group = DispatchGroup()

            for childId in children {
                group.enter()
                db.collection("users").document(userId).collection("children").document(childId).collection("tasks").getDocuments { snapshot, error in
                    if let error = error {
                        print("Fel vid hämtning av uppgifter: \(error.localizedDescription)")
                        group.leave()
                        return
                    }

                    let fetchedTasks = snapshot?.documents.compactMap { doc -> Date? in
                        let task = try? doc.data(as: Task.self)
                        return task?.startDate
                    } ?? []

                    for task in fetchedTasks {
                        allTaskDates.insert(task)
                    }

                    group.leave()
                }
            }

            group.notify(queue: .main) {
                DispatchQueue.main.async {
                    self.taskDates = allTaskDates
                }
            }
        }
    }

    
    private func isTaskRecurringOnDate(_ task: Task, _ date: Date) -> Bool {
        let calendar = Calendar.current
        guard let startDate = task.startDate else { return false }

        if let endDate = task.endDate, calendar.compare(date, to: endDate, toGranularity: .day) == .orderedDescending {
            return false
        }

        if calendar.compare(startDate, to: date, toGranularity: .day) == .orderedDescending {
            return false
        }

        switch task.repeatOption {
        case "Dagligen":
            return true
        case "Varje vecka":
            let weekday = calendar.component(.weekday, from: date)
            let taskWeekday = calendar.component(.weekday, from: startDate)
            return weekday == taskWeekday
        case "Varje månad":
            let taskDay = calendar.component(.day, from: startDate)
            let selectedDay = calendar.component(.day, from: date)
            return taskDay == selectedDay
        case "Varje år":
            let taskMonth = calendar.component(.month, from: startDate)
            let selectedMonth = calendar.component(.month, from: date)
            let taskDay = calendar.component(.day, from: startDate)
            let selectedDay = calendar.component(.day, from: date)
            return taskMonth == selectedMonth && taskDay == selectedDay
        default:
            return false
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
            var filteredTasks: [Task] = []
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

                    let calendar = Calendar.current

                    let tasksForSelectedDate = fetchedTasks.filter { task in
                        if task.type == "oneTime", let taskDate = task.startDate {
                            return calendar.isDate(taskDate, inSameDayAs: selectedDate)
                        } else if task.type == "recurring" {
                            return isTaskRecurringOnDate(task, selectedDate)
                        }
                        return false
                    }

                    filteredTasks.append(contentsOf: tasksForSelectedDate)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                DispatchQueue.main.async {
                    self.tasks = filteredTasks
                }
            }
        }
    }


    private func isTaskOnDate(_ task: Task, _ date: Date) -> Bool {
        if let taskDate = task.date {
            return Calendar.current.isDate(taskDate, inSameDayAs: date)
        }
        return false
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
