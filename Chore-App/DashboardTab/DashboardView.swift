//Dashboard with progress bars for money and screen time
import SwiftUI
import Firebase
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var moneyEarned: Int = 0
    @State private var screenTimeEarned: Int = 0
    
    var body: some View {
        VStack {
            // 🔹 Barnväljare
            Picker("Välj barn", selection: $selectedChild) {
                ForEach(children, id: \.id) { child in
                    Text(child.name).tag(Optional(child))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .onChange(of: selectedChild) { _, _ in
                updateChildProgress()
            }

            // 🔹 Välkomstmeddelande
            Text("Välkommen, \(authService.user?.name ?? "User")!")
                .font(.largeTitle)
                .padding()
            
            if let child = selectedChild {
                Text("\(child.name)'s saldo: \(child.balance) SEK")
                    .font(.title2)
                    .padding()
                
                HStack(spacing: 40) {
                    VStack {
                        ProgressRing(progress: CGFloat(moneyEarned) / CGFloat(child.weeklyGoal))
                            .frame(width: 120, height: 120)
                        Text("\(moneyEarned) SEK")
                            .font(.headline)
                    }

                    VStack {
                        ProgressRing(progress: CGFloat(screenTimeEarned) / 120)
                            .frame(width: 120, height: 120)
                        Text("\(screenTimeEarned) min skärmtid")
                            .font(.headline)
                    }
                }
                .padding()
                
                // 🔹 Veckans mål (editbar)
                HStack {
                    Text("Veckans mål i kronor:")
                    TextField("Mål", value: Binding(
                        get: { selectedChild?.weeklyGoal ?? 50 }, // 🟢 Använd defaultvärde om `weeklyGoal` saknas
                        set: { newGoal in saveWeeklyGoal(newGoal) }
                    ), formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                }
                .padding()
                
                // 🔹 Lägg till syssla-knapp
                NavigationButton(title: "Lägg till syssla eller uppgift", destination: AddItemView(selectedChild: child))
            }
        }
        .padding()
        .onAppear {
            loadChildren()
            updateChildProgress()
            addMissingWeeklyGoal()
        }
        .onChange(of: selectedChild) { _, _ in
            updateChildBalance()
            updateChildProgress()
        }
    }
    
    private func addMissingWeeklyGoal() {
        guard let parentId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Fel vid uppdatering av barn: \(error.localizedDescription)")
                return
            }
            
            for document in snapshot?.documents ?? [] {
                let childRef = db.collection("users").document(parentId).collection("children").document(document.documentID)
                
                if document.data()["weeklyGoal"] == nil {
                    childRef.updateData(["weeklyGoal": 50]) { error in
                        if let error = error {
                            print("❌ Fel vid tillägg av weeklyGoal: \(error.localizedDescription)")
                        } else {
                            print("✅ Lagt till weeklyGoal för \(document.documentID)")
                        }
                    }
                }
            }
        }
    }


    
    // 🔹 Ladda barn från Firestore
    private func loadChildren() {
        guard let parentId = authService.user?.id else {
            print("❌ Ingen användare inloggad!")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Fel vid hämtning av barn: \(error.localizedDescription)")
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
                
                return Child(id: doc.documentID, name: name, avatar: avatar, balance: balance, weeklyGoal: weeklyGoal)
            } ?? []
            
            print("📥 Laddade barn: \(self.children.map { "\($0.name) (ID: \($0.id))" })")
            
            if self.selectedChild == nil, !self.children.isEmpty {
                self.selectedChild = self.children.first
                print("🎯 Valde barn: \(self.selectedChild?.name ?? "Ingen")")
            }
        }
    }
    
    // 🔹 Uppdatera sysslor och skärmtid
    private func updateChildProgress() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").document(child.id).collection("chores")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading chores: \(error.localizedDescription)")
                    return
                }
                
                let allChores = snapshot?.documents.compactMap { try? $0.data(as: Chore.self) } ?? []
                let moneyTotal = allChores.filter { $0.rewardType == "money" && $0.completed > 0 }.reduce(0) { $0 + $1.value }
                let screenTimeTotal = allChores.filter { $0.rewardType == "screenTime" && $0.completed > 0 }.reduce(0) { $0 + $1.value }
                
                DispatchQueue.main.async {
                    self.moneyEarned = moneyTotal
                    self.screenTimeEarned = screenTimeTotal
                }
            }
    }
    
    // 🔹 Uppdatera saldo
    private func updateChildBalance() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").document(child.id).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching balance: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), let balance = data["balance"] as? Int {
                DispatchQueue.main.async {
                    self.selectedChild?.balance = balance
                }
            }
        }
    }
    
    // 🔹 Uppdatera veckans mål i Firestore
    private func saveWeeklyGoal(_ newGoal: Int) {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }

        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(child.id)
        
        childRef.updateData(["weeklyGoal": newGoal]) { error in
            if let error = error {
                print("❌ Fel vid uppdatering av veckomål: \(error.localizedDescription)")
            } else {
                print("✅ Veckomål uppdaterat till \(newGoal) SEK")
                DispatchQueue.main.async {
                    self.selectedChild?.weeklyGoal = newGoal
                }
            }
        }
    }
    
    // 🔹 Lyssna på saldoändringar
    private func listenToChildBalance(childId: String) {
        guard let parentId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").document(childId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to balance updates: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(), let balance = data["balance"] as? Int {
                    DispatchQueue.main.async {
                        if let index = self.children.firstIndex(where: { $0.id == childId }) {
                            self.children[index].balance = balance
                        }
                        if self.selectedChild?.id == childId {
                            self.selectedChild?.balance = balance
                        }
                    }
                }
            }
    }
}
