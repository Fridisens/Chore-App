
import Firebase
import FirebaseAuth
import Foundation

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    
    
    
    func addChore(for userId: String, childId: String, chore: Chore, completion: @escaping (Result<Void, Error>) -> Void) {
        let choreRef = db.collection("users").document(userId).collection("children").document(childId).collection("chores").document()
        var newChore = chore
        newChore.id = choreRef.documentID
        
        do {
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
    
    func updateChore(for parentId: String, childId: String, chore: Chore, completion: @escaping (Result<Void, Error>) -> Void) {
            let choreRef = db.collection("users").document(parentId).collection("children").document(childId).collection("chores").document(chore.id)
            
            choreRef.setData([
                "name": chore.name,
                "value": chore.value,
                "frequency": chore.frequency,
                "completed": chore.completed,
                "assignedBy": chore.assignedBy
            ], merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    
    

    func listenToChores(for userId: String, childId: String, completion: @escaping ([Chore]) -> Void) {
        db.collection("users").document(userId).collection("children").document(childId).collection("chores")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading chores: \(error.localizedDescription)")
                    return
                }
                let chores = snapshot?.documents.compactMap { try? $0.data(as: Chore.self) } ?? []
                completion(chores)
            }
    }
}
