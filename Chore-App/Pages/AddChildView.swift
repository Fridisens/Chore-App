import SwiftUI
import Firebase
import FirebaseAuth

struct AddChildView: View {
    
    var onChildAdded: () -> Void
    @State private var childName = ""
    @Binding var isAddingChild: Bool
    
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Barnets namn", text: $childName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Lägg till barn") {
                    addChild()
                }
                .padding()
                .disabled(childName.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Add Child")
            .navigationBarItems(leading:
                                    Button("Tillbaka") {
                isAddingChild = false
            }
            )
        }
    }
    
    private func addChild() {
        guard let parentId = Auth.auth().currentUser?.uid, !childName.isEmpty else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document()
        
        let newChild = Child(id: childRef.documentID, name: childName, avatar: "avatar1", balance: 0)
        
        
        do {
            try childRef.setData(from: newChild) { error in
                if let error = error {
                    print("Error adding child: \(error.localizedDescription)")
                } else {
                    onChildAdded()
                    isAddingChild = false
                }
            }
        } catch {
            print("Error encoding child: \(error.localizedDescription)")
        }
    }
}
