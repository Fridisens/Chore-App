import SwiftUI
import Firebase
import FirebaseAuth

import SwiftUI
import Firebase

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
                self.tasks = allTasks.filter { isTaskOnDate($0, self.selectedDate) }
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
