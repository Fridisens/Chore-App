import SwiftUI
import Firebase
import FirebaseAuth

struct AddChildView: View {
    
    var onChildAdded: () -> Void
    @State private var childName = ""
    @Binding var isAddingChild: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Lägg till nytt barn")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                TextField("Barnets namn", text: $childName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: addChild) {
                    Text("Lägg till barn")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(childName.isEmpty ? Color.gray.opacity(0.5) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(childName.isEmpty)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Lägg till barn")
            .navigationBarItems(trailing:
                                    Button(action: {
                isAddingChild = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.purple.opacity(0.7))
                    .padding()
            }
            )
        }
    }
    
    private func addChild() {
        guard let parentId = Auth.auth().currentUser?.uid, !childName.isEmpty else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document()
        
        let newChild = Child(
            id: childRef.documentID,
            name: childName,
            avatar: "avatar1",
            balance: 0,
            savings: 1000,
            weeklyGoal: 50
        )
        
        do {
            try childRef.setData(from: newChild) { error in
                if let error = error {
                    print("Error adding child: \(error.localizedDescription)")
                } else {
                    print("Barn tillagt: \(newChild.name) med veckomål \(newChild.weeklyGoal) SEK")
                    onChildAdded()
                    isAddingChild = false
                }
            }
        } catch {
            print("Error encoding child: \(error.localizedDescription)")
        }
    }
}
