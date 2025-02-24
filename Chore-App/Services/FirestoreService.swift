
import FirebaseFirestore


class FirestoreService {
    private let db = Firestore.firestore()
    
    func addChore(for userId: String, chore: Chore, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let choreRef = db.collection("users").document(userId).collection("chores").document()
            var newChore = chore
            newChore.id = choreRef.documentID
            
            try choreRef.setData(from: newChore) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }
}

