import SwiftUI
import Firebase
import FirebaseAuth

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var selectedChild: Child?
    @State private var children: [Child] = []
    @State private var tasks: [Task] = []
    @State private var weeklyItems: [(String, [Any])] = []

    @StateObject private var firestoreService = FirestoreService()
    @EnvironmentObject var authService: AuthService

    private let calendar = Calendar.current
    private let weekdays = ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kalender")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                    .padding(.top)
                    .padding(.horizontal)

                HStack {
                    if !children.isEmpty {
                        Menu {
                            ForEach(children, id: \.id) { child in
                                Button(action: {
                                    selectedChild = child
                                    fetchTasksForSelectedDate()
                                    fetchWeeklyItems()
                                }) {
                                    Label(child.name, image: child.avatar)
                                }
                            }
                        } label: {
                            HStack {
                                if let child = selectedChild {
                                    Image(child.avatar)
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .clipShape(Circle())
                                    Text(child.name)
                                } else {
                                    Text("Välj barn")
                                }
                                Image(systemName: "chevron.down")
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                DatePicker("Välj datum", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(.purple)
                    .padding(.horizontal)
                    .onChange(of: selectedDate) {
                        fetchTasksForSelectedDate()
                        fetchWeeklyItems()
                    }

                if weeklyItems.isEmpty {
                    Text("Inga sysslor eller uppgifter denna vecka")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Veckans Översikt")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding(.horizontal)

                        LazyVStack(spacing: 8) {
                            ForEach(weeklyItems, id: \.0) { weekday, items in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(weekday)
                                        .font(.subheadline)
                                        .foregroundColor(.purple)
                                        .padding(.leading)

                                    ForEach(items.indices, id: \.self) { index in
                                        if let task = items[index] as? Task {
                                            taskRow(task)
                                        } else if let chore = items[index] as? Chore {
                                            choreRow(chore, weekday: weekday)
                                        }
                                    }
                                }
                                .padding(.bottom, 10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            loadChildren()
            addMissingFrequencyField()
        }
    }

    private func taskRow(_ task: Task) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.headline)
                if task.isAllDay {
                    Text("Heldag")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let start = task.startTime, let end = task.endTime {
                    Text("\(formatTime(start)) - \(formatTime(end))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func choreRow(_ chore: Chore, weekday: String) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "sv_SE")
        dateFormatter.dateStyle = .short
        let todayKey = dateFormatter.string(from: selectedDate)

        let isDoneToday = chore.completedDates?[todayKey] == true && chore.days.contains(weekday)

        let statusColor: Color = isDoneToday ? .green : .red

        return HStack {
            VStack(alignment: .leading) {
                Text(chore.name)
                    .font(.headline)
                if let freq = chore.frequency, freq > 1 {
                    let done = chore.completed
                    Text("\(done)/\(freq) gånger utfört")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Circle()
                .fill(statusColor)
                .frame(width: 16, height: 16)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func loadChildren() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("children").getDocuments { snapshot, error in
            let fetched = snapshot?.documents.compactMap { doc -> Child? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let avatar = data["avatar"] as? String else { return nil }
                let balance = data["balance"] as? Int ?? 0
                let savings = data["savings"] as? Int ?? 0
                let weeklyGoal = data["weeklyGoal"] as? Int ?? 50

                return Child(id: doc.documentID, name: name, avatar: avatar, balance: balance, savings: savings, weeklyGoal: weeklyGoal)
            } ?? []

            DispatchQueue.main.async {
                self.children = fetched
                if self.selectedChild == nil, let first = fetched.first {
                    self.selectedChild = first
                    fetchTasksForSelectedDate()
                    fetchWeeklyItems()
                }
            }
        }
    }

    private func fetchTasksForSelectedDate() {
        guard let userId = authService.user?.id,
              let child = selectedChild else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("children").document(child.id).collection("tasks").getDocuments { snapshot, _ in
            let fetched = snapshot?.documents.compactMap { try? $0.data(as: Task.self) } ?? []
            let filtered = fetched.filter {
                guard let date = $0.startDate else { return false }
                return Calendar.current.isDate(date, inSameDayAs: selectedDate)
            }

            DispatchQueue.main.async {
                self.tasks = filtered
            }
        }
    }

    private func fetchWeeklyItems() {
        guard let userId = authService.user?.id,
              let child = selectedChild else { return }

        let db = Firestore.firestore()
        let childRef = db.collection("users").document(userId).collection("children").document(child.id)

        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.dateInterval(of: .weekOfMonth, for: selectedDate)?.end ?? selectedDate

        var weekItems: [Any] = []
        let group = DispatchGroup()

        group.enter()
        childRef.collection("tasks").getDocuments { snapshot, _ in
            let fetched = snapshot?.documents.compactMap { try? $0.data(as: Task.self) } ?? []
            let filtered = fetched.filter { task in
                if task.type == "recurring",
                   let start = task.startDate, let end = task.endDate {
                    return start <= endOfWeek && end >= startOfWeek
                } else if task.type == "oneTime",
                          let taskDate = task.startDate {
                    return taskDate >= startOfWeek && taskDate <= endOfWeek
                }
                return false
            }
            weekItems.append(contentsOf: filtered)
            group.leave()
        }

        group.enter()
        childRef.collection("chores").getDocuments { snapshot, _ in
            let fetched = snapshot?.documents.compactMap { try? $0.data(as: Chore.self) } ?? []
            weekItems.append(contentsOf: fetched)
            group.leave()
        }

        group.notify(queue: .main) {
            self.weeklyItems = self.groupItemsByWeekday(weekItems)
        }
    }

    private func groupItemsByWeekday(_ items: [Any]) -> [(String, [Any])] {
        var grouped: [String: [Any]] = [:]
        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale(identifier: "sv_SE")
        shortFormatter.dateFormat = "E"

        for item in items {
            if let task = item as? Task, let date = task.startDate {
                let day = shortFormatter.string(from: date).capitalized
                grouped[day, default: []].append(task)
            } else if let chore = item as? Chore {
                for day in chore.days {
                    let cap = day.capitalized
                    if weekdays.contains(cap) {
                        grouped[cap, default: []].append(chore)
                    }
                }
            }
        }

        return weekdays.compactMap { day in
            if let items = grouped[day] {
                let sorted = items.sorted {
                    ($0 is Task ? 0 : 1) < ($1 is Task ? 0 : 1)
                }
                return (day, sorted)
            }
            return nil
        }
    }

    private func addMissingFrequencyField() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("children").getDocuments { snapshot, _ in
            for doc in snapshot?.documents ?? [] {
                let childRef = db.collection("users").document(userId).collection("children").document(doc.documentID)
                childRef.collection("chores").getDocuments { snapshot, _ in
                    for choreDoc in snapshot?.documents ?? [] {
                        let choreRef = childRef.collection("chores").document(choreDoc.documentID)
                        if choreDoc.data()["frequency"] == nil {
                            choreRef.updateData(["frequency": 1])
                        }
                    }
                }
            }
        }
    }
}
