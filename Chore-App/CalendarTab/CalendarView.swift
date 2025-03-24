import SwiftUI
import Firebase
import FirebaseAuth

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var tasks: [Task] = []
    @State private var chores: [Chore] = []
    @State private var weeklyItems: [(String, [Any])] = []
    @StateObject private var firestoreService = FirestoreService()
    @EnvironmentObject var authService: AuthService
    
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter
    }()

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
                    fetchWeeklyItems()
                }
       
            if weeklyItems.isEmpty {
                Text("Inga sysslor eller uppgifter denna vecka")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(alignment: .leading) {
                    Text("Veckans Översikt")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .padding(.top, 5)

                    List {
                        ForEach(weeklyItems, id: \.0) { weekday, items in
                            Section(header: Text(weekday).font(.subheadline).foregroundColor(.purple)) {
                                ForEach(items.indices, id: \.self) { index in
                                    if let task = items[index] as? Task {
                                        taskRow(task)
                                    } else if let chore = items[index] as? Chore {
                                        choreRow(chore)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchTasksForSelectedDate()
            fetchWeeklyItems()
            addMissingFrequencyField()
        }
    }

    private func taskRow(_ task: Task) -> some View {
        VStack(alignment: .leading) {
            Text(task.name)
                .font(.headline)
            if task.isAllDay {
                Text("Heldag")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else if let startTime = task.startTime, let endTime = task.endTime {
                Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(5)
    }
    

    private func choreRow(_ chore: Chore) -> some View {
        // 🔢 Räkna ut färgen först
        let totalRequired = chore.frequency ?? 1
        let completed = chore.completed

        let statusColor: Color
        if completed >= totalRequired {
            statusColor = .green
        } else if completed > 0 {
            statusColor = .yellow
        } else {
            statusColor = .red
        }

        // 👇 View-del
        return HStack {
            VStack(alignment: .leading) {
                Text(chore.name)
                    .font(.headline)
                if totalRequired > 1 {
                    Text("\(completed)/\(totalRequired) gånger utfört")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 16, height: 16)
        }
        .padding(5)
    }

    private func fetchWeeklyItems() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.dateInterval(of: .weekOfMonth, for: selectedDate)?.end ?? selectedDate

        print("Veckan: \(startOfWeek) → \(endOfWeek)")

        db.collection("users").document(userId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("Fel vid hämtning av barn: \(error.localizedDescription)")
                return
            }

            let children = snapshot?.documents.compactMap { $0.documentID } ?? []
            print("Hittade \(children.count) barn: \(children)")

            var weekItems: [Any] = []
            let group = DispatchGroup()

            for childId in children {
                let childRef = db.collection("users").document(userId).collection("children").document(childId)

                group.enter()
                childRef.collection("tasks").getDocuments { snapshot, error in
                    let fetchedTasks = snapshot?.documents.compactMap { try? $0.data(as: Task.self) } ?? []

                    print("Tasks för \(childId): \(fetchedTasks.count) st")
                    for task in fetchedTasks {
                        print("— \(task.name), start: \(String(describing: task.startDate)), end: \(String(describing: task.endDate))")
                    }

                    let filtered = fetchedTasks.filter { task in
                        if task.type == "recurring",
                           let startDate = task.startDate,
                           let endDate = task.endDate {
                            return startDate <= endOfWeek && endDate >= startOfWeek
                        } else if task.type == "oneTime",
                                  let taskDate = task.startDate {
                            return taskDate >= startOfWeek && taskDate <= endOfWeek
                        }
                        return false
                    }

                    print("Matchande tasks: \(filtered.map { $0.name })")
                    weekItems.append(contentsOf: filtered)
                    group.leave()
                }

                group.enter()
                childRef.collection("chores").getDocuments { snapshot, error in
                    let fetchedChores = snapshot?.documents.compactMap { try? $0.data(as: Chore.self) } ?? []
                    print("Sysslor för \(childId): \(fetchedChores.map { $0.name })")
                    weekItems.append(contentsOf: fetchedChores)
                    group.leave()
                }
            }

            group.notify(queue: .main) {

                self.weeklyItems = self.groupItemsByWeekday(weekItems)
                print("Totalt antal items i vecka: \(self.weeklyItems.flatMap { $0.1 }.count)")
            }
        }
    }


    private func fetchTasksForSelectedDate() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("children").getDocuments { snapshot, error in
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

                    let tasksForSelectedDate = fetchedTasks.filter { task in
                        return isTaskOnDate(task, selectedDate)
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
        if let taskDate = task.startDate {
            return Calendar.current.isDate(taskDate, inSameDayAs: date)
        }
        return false
    }

    private func groupItemsByWeekday(_ items: [Any]) -> [(String, [Any])] {
        var groupedItems: [String: [Any]] = [:]
        let weekdays = ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]

        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale(identifier: "sv_SE")
        shortFormatter.dateFormat = "E"
        for item in items {
            if let task = item as? Task, let date = task.startDate {
                let weekday = shortFormatter.string(from: date).capitalized
                groupedItems[weekday, default: []].append(task)
            } else if let chore = item as? Chore {
                for day in chore.days {
                    let capitalizedDay = day.capitalized
                    if weekdays.contains(capitalizedDay) {
                        groupedItems[capitalizedDay, default: []].append(chore)
                    }
                }
            }
        }

        for (key, value) in groupedItems {
            print("\(key): \(value.count) items")
        }

        return weekdays.compactMap { day in
            if let items = groupedItems[day] {
                let sorted = items.sorted {
                    ($0 is Task ? 0 : 1) < ($1 is Task ? 0 : 1)
                }
                return (day, sorted)
            }
            return nil
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func addMissingFrequencyField() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("Fel vid hämtning av barn: \(error.localizedDescription)")
                return
            }

            for document in snapshot?.documents ?? [] {
                let childRef = db.collection("users").document(userId).collection("children").document(document.documentID)

                childRef.collection("chores").getDocuments { snapshot, error in
                    if let error = error {
                        print("Fel vid hämtning av sysslor: \(error.localizedDescription)")
                        return
                    }

                    for choreDoc in snapshot?.documents ?? [] {
                        let choreRef = childRef.collection("chores").document(choreDoc.documentID)

                        if choreDoc.data()["frequency"] == nil {
                            choreRef.updateData(["frequency": 1]) { error in
                                if let error = error {
                                    print("Fel vid uppdatering av frequency: \(error.localizedDescription)")
                                } else {
                                    print("Lagt till frequency för syssla: \(choreDoc.documentID)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
