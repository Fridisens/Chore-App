import SwiftUI
import Firebase
import FirebaseAuth

struct ChoreRow: View {
    var chore: Chore
    @Binding var completedChores: [String]
    var selectedChild: Child
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chore.name)
                    .strikethrough(completedChores.contains(chore.id))
                    .padding(.bottom, 2)
                
                Text("\(chore.value) SEK")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                toggleChoreCompletion()
            }) {
                Image(systemName: completedChores.contains(chore.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(completedChores.contains(chore.id) ? .green : .gray)
                    .font(.title)
            }
        }
    }
    
    private func toggleChoreCompletion() {
        guard let parentId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(selectedChild.id)
        
        if completedChores.contains(chore.id) {
            completedChores.removeAll { $0 == chore.id }
            childRef.updateData(["balance": FieldValue.increment(-Int64(chore.value))])
        } else {
            completedChores.append(chore.id)
            childRef.updateData(["balance": FieldValue.increment(Int64(chore.value))])
        }
    }
}
