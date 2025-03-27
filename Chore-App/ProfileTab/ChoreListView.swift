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
    
    private var todayChores: [Chore] {
        chores.filter { $0.days.contains(today) }
    }
    
    var body: some View {
        List {
            Section(header: Text("Dagens sysslor")) {
                ForEach(chores.filter { $0.days.contains(today) }, id: \.id) { chore in
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
        .id(UUID())
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
        for chore in todayChores {
            print("Visar syssla: \(chore.name) på \(chore.days) - Idag är: \(today)")
        }
    }
}
