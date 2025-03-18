import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication

struct ProfilePageView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firestoreService = FirestoreService()
    
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var selectedChore: Chore?
    @State private var isEditingChore = false
    @State private var chores: [Chore] = []
    @State private var completedChores: [String] = []
    @State private var isAddingChild = false
    @State private var selectedAvatar: String = "avatar1"
    @State private var showConfetti = 0
    @State private var weeklyGoal: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if children.isEmpty {
                    VStack {
                        Text("Inga barn tillagda ännu!")
                            .font(.title2)
                            .padding()
                        
                        Button(action: { isAddingChild = true }) {
                            Label("Lägg till barn", systemImage: "person.fill.badge.plus")
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    // 🔹 Barnväljare
                    HStack {
                        ChildPickerView(selectedChild: $selectedChild, children: children) {
                            isAddingChild = true
                        }
                        .padding()
                    }
                    
                    if let child = selectedChild {
                        VStack {
                            Image(child.avatar)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.purple, lineWidth: 3))
                            
                            Text(child.name)
                                .font(.title)
                            
                            
                            .padding()
                        }
                        
                        AvatarPicker(selectedAvatar: $selectedAvatar, onAvatarSelected: saveAvatarToFirebase)
                            .padding()
                        
                        ChoreListView(
                            chores: chores,
                            completedChores: $completedChores,
                            selectedChild: child,
                            onEdit: { chore in
                                print("Tryckt på redigera för: \(chore.name)")
                            },
                            onDelete: deleteChore,
                            onBalanceUpdate: updateSelectedChildBalance
                        )
                        .confettiCannon(trigger: $showConfetti)
                        
                        Spacer()
                    }
                }
            }
            .onAppear {
                loadChildren()
                loadAvatarFromFirebase()
                addMissingWeeklyGoal()
            }
            .onChange(of: selectedChild) { _, newChild in
                if let child = newChild {
                    print("Barn bytt till: \(child.name) (ID: \(child.id)), laddar sysslor...")
                    listenToChores(for: child)
                }
            }
            .sheet(isPresented: $isAddingChild) {
                AddChildView(onChildAdded: {
                    loadChildren()
                    isAddingChild = false
                }, isAddingChild: $isAddingChild)
            }
        }
    }

    
    private func addMissingWeeklyGoal() {
        guard let parentId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("Fel vid uppdatering av barn: \(error.localizedDescription)")
                return
            }
            
            for document in snapshot?.documents ?? [] {
                let childRef = db.collection("users").document(parentId).collection("children").document(document.documentID)
                
                if document.data()["weeklyGoal"] == nil {
                    childRef.updateData(["weeklyGoal": 50]) { error in
                        if let error = error {
                            print("Fel vid tillägg av weeklyGoal: \(error.localizedDescription)")
                        } else {
                            print("Lagt till weeklyGoal för \(document.documentID)")
                        }
                    }
                }
            }
        }
    }


  
    private func saveWeeklyGoal() {
            guard let parentId = authService.user?.id, let child = selectedChild else { return }
            guard let goal = Int(weeklyGoal) else { return }
            
            let db = Firestore.firestore()
            let childRef = db.collection("users").document(parentId).collection("children").document(child.id)
            
            childRef.updateData(["weeklyGoal": goal]) { error in
                if let error = error {
                    print("Fel vid uppdatering av veckomål: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.selectedChild?.weeklyGoal = goal
                    }
                }
            }
        }
    
    
    
    
    
    private func listenToChores(for child: Child) {
           guard let parentId = authService.user?.id else { return }
           
           firestoreService.listenToChores(for: parentId, childId: child.id) { fetchedChores in
               DispatchQueue.main.async {
                   self.chores = fetchedChores
                   print("Uppdaterade sysslor för \(child.name): \(fetchedChores.count) stycken")
               }
           }
       }
    
    
    
    private func loadChores() {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").document(childId).collection("chores").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading chores: \(error.localizedDescription)")
                return
            }
            
            self.chores = snapshot?.documents.compactMap { doc in
                try? doc.data(as: Chore.self)
            } ?? []
        }
    }
    
    private func updateChore(_ chore: Chore) {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }

        let db = Firestore.firestore()
        let choreRef = db.collection("users").document(parentId).collection("children").document(childId).collection("chores").document(chore.id)

        choreRef.setData([
            "name": chore.name,
            "value": chore.value,
            "completed": chore.completed,
            "assignedBy": chore.assignedBy,
            "rewardType": chore.rewardType,
            "days": chore.days
        ], merge: true) { error in
            if let error = error {
                print("Error updating chore: \(error.localizedDescription)")
            } else {
                if let index = chores.firstIndex(where: { $0.id == chore.id }) {
                    chores[index] = chore
                }
            }
        }
    }
    
    private func deleteChore(_ chore: Chore) {
        let context = LAContext()
        var error: NSError?
        
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Autentisera för att radera sysslan: \(chore.name)"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        
                        self.confirmDeleteChore(chore)
                    } else {
                        print("Face ID/Touch ID autentisering misslyckades.")
                    }
                }
            }
        } else {
            print("Face ID/Touch ID är inte tillgängligt på denna enhet.")
        }
    }
    
    private func confirmDeleteChore(_ chore: Chore) {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
        
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(childId)
        
        childRef.collection("chores").document(chore.id).delete { error in
            if let error = error {
                print("Fel vid radering av syssla: \(error.localizedDescription)")
            } else {
                print("Syssla raderad: \(chore.name)")
                
                DispatchQueue.main.async {
                    self.chores.removeAll { $0.id == chore.id }
                }
            }
        }
    }
    
    func updateSelectedChildBalance() {
        guard let parentId = Auth.auth().currentUser?.uid, let child = selectedChild else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(child.id)

        childRef.getDocument { snapshot, error in
            if let error = error {
                print("Fel vid hämtning av saldo: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(),
               let newBalance = data["balance"] as? Int,
               let newGoal = data["weeklyGoal"] as? Int {
                
                DispatchQueue.main.async {
                    self.selectedChild = Child(
                        id: child.id,
                        name: child.name,
                        avatar: child.avatar,
                        balance: newBalance,
                        weeklyGoal: newGoal
                    )
                    print("Uppdaterat saldo: \(newBalance) kr")
                }
            }
        }
    }



    
    private func loadChildren() {
            guard let parentId = authService.user?.id else { return }
            let db = Firestore.firestore()
            
            db.collection("users").document(parentId).collection("children").getDocuments { snapshot, error in
                if let error = error {
                    print("Fel vid hämtning av barn: \(error.localizedDescription)")
                    return
                }
                
                self.children = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Child.self)
                } ?? []
                
                DispatchQueue.main.async {
                    print("Laddade barn: \(self.children.map { "\($0.name) (ID: \($0.id))" })")
                    
                    if self.children.isEmpty {
                        self.selectedChild = nil
                    } else if self.selectedChild == nil {
                        self.selectedChild = self.children.first
                        if let firstChild = self.selectedChild {
                            listenToChores(for: firstChild)
                        }
                    }
                }
            }
        }
    
    private func saveAvatarToFirebase() {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").document(childId).updateData(["avatar": selectedAvatar]) { error in
            if let error = error {
                print("Error saving avatar: \(error.localizedDescription)")
            } else {
                print("Avatar saved successfully!")
                
                DispatchQueue.main.async {
                    self.selectedChild?.avatar = self.selectedAvatar
                }
            }
        }
    }
    
    private func loadAvatarFromFirebase() {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").document(childId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading avatar: \(error.localizedDescription)")
                return
            }
            if let avatar = snapshot?.data()?["avatar"] as? String {
                DispatchQueue.main.async {
                    self.selectedAvatar = avatar
                }
            }
        }
    }
    
    private func deleteChild() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").document(child.id).delete { error in
            if let error = error {
                print("Error deleting child: \(error.localizedDescription)")
            } else {
                print("Child deleted successfully")
                DispatchQueue.main.async {
                    self.children.removeAll { $0.id == child.id }
                    self.selectedChild = children.first
                }
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            authService.user = nil
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
}

