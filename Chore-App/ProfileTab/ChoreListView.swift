import SwiftUI
import FirebaseAuth
import Firebase

struct ChoreListView: View {
    var chores: [Chore]
    @Binding var completedChores: [String]
    var selectedChild: Child
    var onEdit: (Chore) -> Void
    var onDelete: (Chore) -> Void
    
    private var today: String {
        getToday()
    }
    
    var body: some View {
        List {
            Section(header: Text("Dagens sysslor")) {
                ForEach(chores.filter { $0.days.contains(today) }) { chore in
                    ChoreRow(
                        chore: chore,
                        completedChores: $completedChores,
                        selectedChild: selectedChild,
                        onEdit: onEdit,
                        onDelete: onDelete
                    )
                }
            }
        }
    }
    
    private func getToday() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateFormat = "E"  // Returnerar "Mån", "Tis", osv.
        return formatter.string(from: Date())
    }
}
