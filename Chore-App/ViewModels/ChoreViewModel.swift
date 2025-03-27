import FirebaseFirestore


class ChoreViewModel: ObservableObject {
    @Published var chores: [Chore] = []
    private let firestoreService = FirestoreService()
    
    func addChore(for userId: String, childId: String, chore: Chore) {
        firestoreService.addChore(for: userId, childId: childId, chore: chore) { result in
            switch result {
            case .success():
                print("Chore added successfully!")
            case .failure(let error):
                print("Failed to add chore: \(error.localizedDescription)")
            }
        }
    }
    
    func listenToChores(for userId: String, childId: String) {
        firestoreService.listenToChores(for: userId, childId: childId) { updatedChores in
            DispatchQueue.main.async {
                self.chores = updatedChores
            }
        }
    }
}
