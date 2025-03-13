//Dashboard with progress bars for money and screen time
import SwiftUI
import Firebase
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var weeklyGoal: Int = 50
    @State private var moneyEarned: Int = 0
    @State private var screenTimeEarned: Int = 0
    
    var body: some View {
        VStack {
            Picker("Välj barn", selection: $selectedChild) {
                ForEach(children, id: \.self) { child in
                    Text(child.name).tag(Optional(child))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .onChange(of: selectedChild) { _, _ in
                updateChildProgress()
            }

            Text("Välkommen, \(authService.user?.name ?? "User")!")
                .font(.largeTitle)
                .padding()
            
            if let child = selectedChild {
                Text("\(child.name)'s saldo: \(child.balance) SEK")
                    .font(.title2)
                    .padding()
                
                HStack(spacing: 40) {
                    VStack {
                        ProgressRing(progress: CGFloat(moneyEarned) / CGFloat(weeklyGoal))
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
                
                HStack {
                    Text("Veckans mål i kronor:")
                    TextField("Mål", value: $weeklyGoal, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                }
                .padding()
                
                NavigationButton(title: "Lägg till syssla eller uppgift", destination: AddItemView(selectedChild: child))
            }
        }
        .padding()
        .onAppear {
            loadChildren()
            updateChildProgress()
        }
        .onChange(of: selectedChild) { _, _ in
            updateChildBalance()
            updateChildProgress()
        }
        
    }
    
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
    
    private func loadChildren() {
        guard let parentId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading children: \(error.localizedDescription)")
                return
            }
            
            self.children = snapshot?.documents.compactMap { doc in
                try? doc.data(as: Child.self)
            } ?? []
            
            if selectedChild == nil, !children.isEmpty {
                selectedChild = children.first
                if let firstChild = children.first {
                    listenToChildBalance(childId: firstChild.id)
                }
            }
        }
    }
    
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
