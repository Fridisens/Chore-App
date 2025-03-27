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
            VStack(spacing: 16) {
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
                            HStack(spacing: 8) {
                                if let child = selectedChild {
                                    Image(child.avatar)
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .clipShape(Circle())
                                    Text(child.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Välj barn")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                DatePicker("Välj datum", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(.purple)
                    .padding()
                    .onChange(of: selectedDate) {
                        fetchTasksForSelectedDate()
                        fetchWeeklyItems()
                    }

                Text("Veckans Översikt")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.purple)
                    .padding(.top)

                ForEach(weeklyItems, id: \.0) { weekday, items in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(weekday)
                            .font(.headline)
                            .foregroundColor(.purple)

                        VStack(spacing: 6) {
                            if items.contains(where: { $0 is Chore }) {
                                Text("Sysslor")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 4)
                                ForEach(items.compactMap { $0 as? Chore }, id: \.id) { chore in
                                    HStack(spacing: 10) {
                                        Image(systemName: chore.icon)
                                            .foregroundColor(.purple)
                                            .padding(8)
                                            .background(Circle().fill(Color.purple.opacity(0.1)))
                                        Text(chore.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color.purple.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }

                            if items.contains(where: { $0 is Task }) {
                                Text("Uppgifter")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                                    .padding(.leading, 4)
                                ForEach(items.compactMap { $0 as? Task }, id: \.id) { task in
                                    HStack(spacing: 10) {
                                        Image(systemName: task.icon)
                                            .foregroundColor(.blue)
                                            .padding(8)
                                            .background(Circle().fill(Color.blue.opacity(0.1)))
                                        VStack(alignment: .leading) {
                                            Text(task.name)
                                                .font(.body)
                                            if !task.isAllDay, let start = task.startTime, let end = task.endTime {
                                                Text("\(formatTime(start)) - \(formatTime(end))")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        Divider()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            loadChildren()
            addMissingFrequencyField()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func loadChildren() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userId).collection("children").getDocuments { snapshot, _ in
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
