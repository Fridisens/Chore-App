import FirebaseAuth
import FirebaseFirestore


class AuthService: ObservableObject {
    @Published var user: User?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    func registerUser(email: String, password: String, name: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let firebaseUser = result?.user {
                let newUser = User(id: firebaseUser.uid, name: name, email: email, balance: 0, rewardType: "money")
                
                self.db.collection("users").document(firebaseUser.uid).setData([
                    "id": newUser.id,
                    "name": newUser.name,
                    "email": newUser.email,
                    "balance": newUser.balance,
                    "rewardType": newUser.rewardType
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        
                    } else {
                        self.user = newUser
                        completion(.success(newUser))
                    }
                }
            }
            
        }
    }

    func login (email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.fetchCurrentUser()
            completion(.success(()))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(.success(()))
            }
        }
    }
    
    func fetchCurrentUser() {
        guard let currentUser = auth.currentUser else {
            self.user = nil
            return
        }
        
        let userRef = db.collection("users").document(currentUser.uid)
        userRef.getDocument { snapshot, error in
            if let error = error {
                print (" error fetching user: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.user = User(
                        id: currentUser.uid,
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        balance: data["balance"] as? Int ?? 0,
                        rewardType: data["rewardType"] as? String ?? "money"
                    )
                }
            }
        }
    }
    
    func logout() {
        do {
            try auth.signOut()
            self.user = nil
        } catch {
            print("Error at logout: \(error)")
        }
    }
}
