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
    @State private var weeklyMoneyGoal: Int = 50
    @State private var showAddMoneyDialog = false
    @State private var moneyToAdd = ""
    @State private var showSuccessOverlay = false
    @State private var showAddChildView = false
    
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            ChildPickerView(
                                selectedChild: $selectedChild,
                                children: children,
                                onAddChild: {
                                    showAddChildView = true
                                }
                            )
                            .padding()
                            
                            Button(action: {
                                showAddChildView = true
                            }) {
                                Image(systemName: "person.fill.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            .padding(.trailing)
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
                                            Image("icons8-piggy-bank-64")
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
                                    if chores.isEmpty {
                                        VStack(spacing: 12) {
                                            Image(systemName: "checkmark.seal")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray.opacity(0.4))
                                            Text("Inga sysslor ännu")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, 50)
                                    } else {
                                        ChoreListView(
                                            chores: chores,
                                            completedChores: $completedChores,
                                            selectedChild: child,
                                            onEdit: { chore in
                                                self.selectedChore = chore
                                                self.isEditingChore = true
                                            },
                                            onDelete: deleteChore,
                                            onBalanceUpdate: updateSelectedChildBalance,
                                            onTriggerConfetti: {
                                                showConfetti += 1
                                                withAnimation {
                                                    showSuccessOverlay = true
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    withAnimation {
                                                        showSuccessOverlay = false
                                                    }
                                                }
                                            }
                                        )
                                        .confettiCannon(trigger: $showConfetti)
                                        .frame(minHeight: UIScreen.main.bounds.height * 0.4)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Button(action: {
                            showLogoutAlert()
                        }) {
                            Label("Logga ut", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    
                    
                    .padding(.top, 10)
                    .onAppear {
                        loadChildren()
                        loadAvatarFromFirebase()
                        addMissingWeeklyGoal()
                    }
                    .onChange(of: selectedChild) { _, newChild in
                        if let child = newChild {
                            listenToChores(for: child)
                        }
                    }
                    
                    .sheet(isPresented: $showAddChildView) {
                        AddChildView(onChildAdded: {
                            loadChildren()
                            showAddChildView = false
                        }, isAddingChild: $showAddChildView)
                    }
                    .sheet(isPresented: $isAddingChild) {
                        AddChildView(onChildAdded: {
                            loadChildren()
                            isAddingChild = false
                        }, isAddingChild: $isAddingChild)
                    }
                    .sheet(isPresented: $isEditingChore) {
                        if let choreToEdit = selectedChore {
                            EditChoreView(
                                chore: Binding(
                                    get: { choreToEdit },
                                    set: { newChore in
                                        updateChore(newChore)
                                    }
                                ),
                                onSave: {
                                    if let choreToEdit = selectedChore {
                                        updateChore(choreToEdit)
                                    }
                                }
                            )
                        }
                    }
                }
                
                if showSuccessOverlay {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("Bra jobbat!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSuccessOverlay)
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
                
                let today = getTodayKey()
                self.completedChores = fetchedChores.compactMap { chore in
                    chore.completedDates?[today] == true ? chore.id : nil
                }
            }
        }
    }
    
    private func getTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: Date())
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
                DispatchQueue.main.async {
                    if let index = self.chores.firstIndex(where: { $0.id == chore.id }) {
                        self.chores[index] = chore
                    }
                    self.isEditingChore = false
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
            print("Face ID/Touch ID ej tillgängligt – visar vanlig bekräftelse")
            
            let alert = UIAlertController(title: "Radera syssla", message: "Är du säker på att du vill ta bort '\(chore.name)'?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Avbryt", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Radera", style: .destructive) { _ in
                self.confirmDeleteChore(chore)
            })
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    private func confirmDeleteChore(_ chore: Chore) {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
        
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(childId)
        
        print("Försöker radera från Firestore: users/\(parentId)/children/\(childId)/chores/\(chore.id)")
        
        childRef.collection("chores").document(chore.id).delete { error in
            if let error = error {
                print("Fel vid radering av syssla: \(error.localizedDescription)")
            } else {
                print("Syssla raderad i Firestore: \(chore.name)")
                
                if let child = selectedChild {
                    listenToChores(for: child)
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
            
            if let data = snapshot?.data() {
                let newBalance = data["balance"] as? Int ?? 0
                let newGoal = data["weeklyGoal"] as? Int ?? 50
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
                      let avatar = data["avatar"] as? String else {
                    print("Saknade namn eller avatar i dokumentet: \(data)")
                    return nil
                }
                
                let balance = data["balance"] as? Int ?? 0
                let savings = data["savings"] as? Int ?? 0
                let weeklyGoal = data["weeklyGoal"] as? Int ?? 50
                
                return Child(id: doc.documentID, name: name, avatar: avatar, balance: balance, savings: savings, weeklyGoal: weeklyGoal)
            } ?? []
            
            DispatchQueue.main.async {
                print("Laddade barn: \(self.children.map { "\($0.name) (ID: \($0.id))" })")
                
                if self.selectedChild == nil, !self.children.isEmpty {
                    self.selectedChild = self.children.first
                    self.weeklyMoneyGoal = self.selectedChild?.weeklyGoal ?? 50
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
    
    private func showLogoutAlert() {
        let alert = UIAlertController(title: "Logga ut", message: "Är du säker på att du vill logga ut?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Avbryt", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logga ut", style: .destructive) { _ in
            logout()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
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

