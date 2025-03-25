import SwiftUI
import ConfettiSwiftUI
import Firebase
import FirebaseAuth

struct ChoreRow: View {
    var chore: Chore
    @Binding var completedChores: [String]
    var selectedChild: Child
    var onEdit: (Chore) -> Void
    var onDelete: (Chore) -> Void
    var onBalanceUpdate: () -> Void
    var onTriggerConfetti: () -> Void

    private func getTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Ikon
            if !chore.icon.isEmpty {
                Image(systemName: chore.icon)
                    .font(.title2)
                    .foregroundColor(completedChores.contains(chore.id) ? .white : .purple)
                    .frame(width: 30, height: 30)
            }

            // Textinnehåll
            VStack(alignment: .leading) {
                Text(chore.name)
                    .foregroundColor(completedChores.contains(chore.id) ? .white : .primary)
                    .padding(.bottom, 2)

                Text("\(chore.value) \(chore.rewardType == "money" ? "KRONOR" : "MIN SKÄRMTID")")
                    .font(.subheadline)
                    .foregroundColor(completedChores.contains(chore.id) ? .white : .gray)
            }

            Spacer()
        }
        .padding()
        .background(completedChores.contains(chore.id) ? Color.green.opacity(0.8) : Color.clear)
        .cornerRadius(10)
        .animation(.easeInOut, value: completedChores.contains(chore.id))
        .onTapGesture {
            toggleChoreCompletion()
        }
        .swipeActions {
            Button(role: .destructive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete(chore)
                }
            } label: {
                Label("Ta bort", systemImage: "trash")
            }
            .tint(.red)

            Button {
                onEdit(chore)
            } label: {
                Label("Redigera", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private func toggleChoreCompletion() {
        guard let parentId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(selectedChild.id)
        let choreRef = childRef.collection("chores").document(chore.id)

        let todayKey = getTodayKey()
        let valueToUpdate = chore.value

        if completedChores.contains(chore.id) {
            completedChores.removeAll { $0 == chore.id }

            choreRef.updateData([
                "completedDates.\(todayKey)": FieldValue.delete(),
                "completed": FieldValue.increment(Int64(-1))
            ])

            if chore.rewardType == "money" {
                let newBalance = max(0, selectedChild.balance - valueToUpdate)
                childRef.updateData(["balance": newBalance]) { error in
                    if error == nil {
                        onBalanceUpdate()
                    } else {
                        print("Fel vid uppdatering av saldo: \(error!.localizedDescription)")
                    }
                }
            } else if chore.rewardType == "screenTime" {
                let newScreenTime = max(0, selectedChild.balance - valueToUpdate)
                childRef.updateData(["screenTime": newScreenTime]) { error in
                    if error == nil {
                        onBalanceUpdate()
                    } else {
                        print("Fel vid uppdatering av skärmtid: \(error!.localizedDescription)")
                    }
                }
            }

        } else {
            completedChores.append(chore.id)

            choreRef.updateData([
                "completedDates.\(todayKey)": true,
                "completed": FieldValue.increment(Int64(1))
            ])

            onTriggerConfetti()

            if chore.rewardType == "money" {
                let newBalance = selectedChild.balance + valueToUpdate
                childRef.updateData(["balance": newBalance]) { error in
                    if error == nil {
                        onBalanceUpdate()
                    } else {
                        print("Fel vid uppdatering av saldo: \(error!.localizedDescription)")
                    }
                }
            } else if chore.rewardType == "screenTime" {
                let newScreenTime = selectedChild.balance + valueToUpdate
                childRef.updateData(["screenTime": newScreenTime]) { error in
                    if error == nil {
                        onBalanceUpdate()
                    } else {
                        print("Fel vid uppdatering av skärmtid: \(error!.localizedDescription)")
                    }
                }
            }
        }
    }
}
