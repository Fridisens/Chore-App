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
    
    @State private var showConfetti = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chore.name)
                    .foregroundColor(completedChores.contains(chore.id) ? .white : .primary)
                    .padding(.bottom, 2)
                
                Text("\(chore.value) SEK")
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
        .confettiCannon(trigger: $showConfetti)
        .swipeActions {
            Button(role: .destructive) {
                print("Trycker på radera för: \(chore.name)")
                onDelete(chore)
            } label: {
                Label("Ta bort", systemImage: "trash")
            }
            .tint(.red)
            
            Button {
                print("Tryckt på redigera för: \(chore.name)")
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

        if completedChores.contains(chore.id) {
            completedChores.removeAll { $0 == chore.id }
            choreRef.updateData(["completed": 0])
            
            childRef.updateData(["balance": FieldValue.increment(-Int64(chore.value))]) { error in
                if let error = error {
                    print("❌ Fel vid minskning av saldo: \(error.localizedDescription)")
                } else {
                    print("💰 Saldot minskat med \(chore.value) kr")
                    onBalanceUpdate() // 🔄 Be ProfilePageView att uppdatera saldot
                }
            }
        } else {
            completedChores.append(chore.id)
            choreRef.updateData(["completed": 1])
            
            childRef.updateData(["balance": FieldValue.increment(Int64(chore.value))]) { error in
                if let error = error {
                    print("❌ Fel vid ökning av saldo: \(error.localizedDescription)")
                } else {
                    print("💰 Saldot ökat med \(chore.value) kr")
                    onBalanceUpdate() // 🔄 Be ProfilePageView att uppdatera saldot
                }
            }
            
            showConfetti += 1
        }
    }
}
