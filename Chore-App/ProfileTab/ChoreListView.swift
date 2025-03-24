import SwiftUI
import FirebaseAuth
import Firebase

struct ChoreListView: View {
    var chores: [Chore]
    @Binding var completedChores: [String]
    var selectedChild: Child
    var onEdit: (Chore) -> Void
    var onDelete: (Chore) -> Void
    var onBalanceUpdate: () -> Void
    var onTriggerConfetti: () -> Void
    
    private var today: String {
        getToday()
    }
    
    var body: some View {
        List {
            Section(header: Text("Dagens sysslor")) {
                let todayChores = chores.filter { $0.days.contains(today) }
                
                ForEach(todayChores) { chore in
                    ChoreRow(
                        chore: chore,
                        completedChores: $completedChores,
                        selectedChild: selectedChild,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onBalanceUpdate: onBalanceUpdate,
                        onTriggerConfetti: onTriggerConfetti
                    )
                }
            }
        }
        .onAppear {
            debugLog()
        }
    }
    
    private func getToday() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateFormat = "E"
        return formatter.string(from: Date()).capitalized
    }
    
    
    private func debugLog() {
        print("Mottagna sysslor i ChoreListView:", chores.map { "\($0.name) - Dagar: \($0.days)" })
        print("Dagens dag: \(today)")
        let todayChores = chores.filter { $0.days.contains(today) }
        for chore in todayChores {
            print("Visar syssla: \(chore.name) på \(chore.days) - Idag är: \(today)")
        }
    }
}
