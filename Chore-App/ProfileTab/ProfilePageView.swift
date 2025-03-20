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
    @State private var showAddMoneyDialog = false
    @State private var moneyToAdd = ""
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
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
                        HStack {
                            ChildPickerView(selectedChild: $selectedChild, children: children) {
                                isAddingChild = true
                            }
                            .padding()
                        }
                        
                        if let child = selectedChild {
                            VStack(spacing: 20) {
                                
                                
                                HStack(spacing: 15) {
                                    Image(child.avatar)
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.purple, lineWidth: 3))
                                    
                                    Text(child.name)
                                        .font(.title2)
                                        .bold()
                                    
                                    Spacer()
                                    
                                    
                                    ZStack {
                                        ProgressRing(progress: CGFloat(child.savings) / 1000)
                                            .frame(width: 90, height: 90)
                                            .onLongPressGesture {
                                                showAddMoneyAlert()
                                            }
                                        
                                        VStack {
                                            Text("Spargris")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                            Text("\(child.savings) SEK")
                                                .font(.caption)
                                                .foregroundColor(.purple)
                                        }
                                    }

                                }
                                .padding(.horizontal, 20)
                        
                                VStack(alignment: .leading, spacing: 10) {
                                    AvatarPicker(selectedAvatar: $selectedAvatar, onAvatarSelected: saveAvatarToFirebase)
                                }
                                .padding(.horizontal, 20)
                                
                         
                                VStack(alignment: .leading, spacing: 10) {
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
                                    .frame(minHeight: 200)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 10)
                .onAppear {
                    loadChildren()
                    loadAvatarFromFirebase()
                    addMissingWeeklyGoal()
                    addMissingSavingsField()
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
    }



    
    private func addMissingSavingsField() {
        guard let parentId = authService.user?.id else { return }
        let db = Firestore.firestore()

        db.collection("users").document(parentId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("Fel vid uppdatering av barn: \(error.localizedDescription)")
                return
            }

            for document in snapshot?.documents ?? [] {
                let childRef = db.collection("users").document(parentId).collection("children").document(document.documentID)

                if document.data()["savings"] == nil {
                    childRef.updateData(["savings": 0]) { error in
                        if let error = error {
                            print("Fel vid tillägg av savings: \(error.localizedDescription)")
                        } else {
                            print("Lagt till savings för \(document.documentID)")
                        }
                    }
                }
            }
        }
    }

    private func showAddMoneyAlert() {
        let alert = UIAlertController(title: "Lägg till pengar", message: "Ange belopp att lägga till i spargrisen", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Belopp"
            textField.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Avbryt", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Spara", style: .default) { _ in
            if let amount = Int(alert.textFields?.first?.text ?? ""), amount > 0 {
                self.addToSavings(amount)
            }
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

    private func addToSavings(_ amount: Int) {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(child.id)

        childRef.updateData(["savings": child.savings + amount]) { error in
            if let error = error {
                print("Fel vid uppdatering av spargris: \(error.localizedDescription)")
            } else {
                print("Spargris uppdaterad med \(amount) SEK!")
                DispatchQueue.main.async {
                    self.selectedChild?.savings += amount
                }
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
    
    private func transferWeeklyEarningsToSavings() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(child.id)

        let newSavings = child.savings + child.balance
        
        childRef.updateData([
            "savings": newSavings,
            "balance": 0
        ]) { error in
            if let error = error {
                print("Fel vid överföring av veckosaldo: \(error.localizedDescription)")
            } else {
                print("Veckans saldo flyttat till spargrisen!")
                DispatchQueue.main.async {
                    self.selectedChild?.savings = newSavings
                    self.selectedChild?.balance = 0
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

                let newSavings = data["savings"] as? Int ?? 0

                DispatchQueue.main.async {
                    self.selectedChild = Child(
                        id: child.id,
                        name: child.name,
                        avatar: child.avatar,
                        balance: newBalance,
                        savings: newSavings,
                        weeklyGoal: newGoal
                    )
                    print("Uppdaterat saldo: \(newBalance) kr, Spargris: \(newSavings) kr")
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
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let avatar = data["avatar"] as? String,
                      let balance = data["balance"] as? Int,
                      let weeklyGoal = data["weeklyGoal"] as? Int else {
                    print("⚠️ Saknade fält i dokumentet: \(data)")
                    return nil
                }

                let savings = data["savings"] as? Int ?? 0

                return Child(id: doc.documentID, name: name, avatar: avatar, balance: balance, savings: savings, weeklyGoal: weeklyGoal)
            } ?? []

            DispatchQueue.main.async {
                print("✅ Laddade barn: \(self.children.map { "\($0.name) (ID: \($0.id))" })")

                if self.children.isEmpty {
                    self.selectedChild = nil
                } else if self.selectedChild == nil {
                    self.selectedChild = self.children.first
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

