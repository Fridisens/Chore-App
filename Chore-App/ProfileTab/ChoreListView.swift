import SwiftUI

struct ChoreListView: View {
    var chores: [Chore]
    @Binding var completedChores: [String]
    var selectedChild: Child
    var onEdit: (Chore) -> Void

    var body: some View {
        List {
            Section(header: Text("Dagens sysslor")) {
                ForEach(chores.filter { $0.frequency == 1 }) { chore in
                    ChoreRow(
                        chore: chore,
                        completedChores: $completedChores,
                        selectedChild: selectedChild,
                        onEdit: onEdit
                    )
                }
            }

            Section(header: Text("Veckans sysslor")) {
                ForEach(chores.filter { $0.frequency > 1 }) { chore in
                    ChoreRow(
                        chore: chore,
                        completedChores: $completedChores,
                        selectedChild: selectedChild,
                        onEdit: onEdit
                    )
                }
            }
        }
    }
}


