import FirebaseFirestore


class ChoreViewModel: ObservableObject {
    private let firestoreService = FirestoreService()
    private let testUserId = "testUserId"
    
    @Published var chores =  [Chore] ()
    
    func addTestChore() {
        let chore = Chore(id: "", name: "städa rummet", value: 10, frequency: 3, completed: 0, assignedBy: "parentId")
        
        firestoreService.addChore(for: testUserId, chore: chore) { result in
            switch result {
            case .success(_):
                print("Chore added in firestore")
            case .failure(_):
                print("Chore failed in firestore")
            }
        }
    }
    
    private var db = Firestore.firestore()
    
    
    func fetchChores(for userId: String) {
        db.collection("users").document(userId).collection("chores").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("error fetching chores: \(error)")
                return
            }
            
            self.chores = snapshot?.documents.compactMap {doc in
                try? doc.data(as: Chore.self)
                
            } ?? []
        }
    }
}
