import SwiftUI
import Firebase
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var moneyEarned: Int = 0
    @State private var screenTimeEarned: Int = 0
    @State private var weeklyMoneyGoal: Int = 50
    @State private var weeklyScreenTimeGoal: Int = 30
    @State private var isEditingMoneyGoal = false
    @State private var isEditingScreenTimeGoal = false
    
    enum ActiveSheet: Identifiable {
        case addChild, addItem
        
        var id: Int { hashValue }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        VStack {
            if children.isEmpty {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Inga barn tillagda ännu")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        activeSheet = .addChild
                    }) {
                        Label("Lägg till barn", systemImage: "person.fill.badge.plus")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ChildPickerView(selectedChild: $selectedChild, children: children, onAddChild: {
                            activeSheet = .addChild
                        })
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    if selectedChild != nil {
                        Text("Välkommen, \(authService.user?.name ?? "User")!")
                            .font(.largeTitle)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        VStack(spacing: 30) {
                            goalProgressView(
                                title: "Pengar",
                                value: moneyEarned,
                                goal: weeklyMoneyGoal,
                                unit: "SEK",
                                emoji: "💰",
                                isEditing: $isEditingMoneyGoal,
                                editAction: saveMoneyGoal
                            )
                            .padding(.bottom, 20)
                            
                            goalProgressView(
                                title: "Skärmtid",
                                value: screenTimeEarned,
                                goal: weeklyScreenTimeGoal,
                                unit: "min",
                                emoji: "📱",
                                isEditing: $isEditingScreenTimeGoal,
                                editAction: saveScreenTimeGoal
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        Button(action: {
                            activeSheet = .addItem
                        }) {
                            Label("Lägg till syssla eller uppgift", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.bottom)
        .onAppear {
            loadChildren()
            updateChildProgress()
            addMissingSavingsField()
        }
        .onChange(of: selectedChild) { _, _ in
            updateChildBalance()
            updateChildProgress()
        }
        
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addChild:
                AddChildView(onChildAdded: {
                    loadChildren()
                    activeSheet = nil
                }, isAddingChild: .constant(false))
                
            case .addItem:
                if let child = selectedChild {
                    AddItemView(selectedChild: child)
                }
            }
        }
    }
    
    private func goalProgressView(title: String, value: Int, goal: Int, unit: String, emoji: String, isEditing: Binding<Bool>, editAction: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            ZStack {
                ProgressRing(progress: CGFloat(value) / CGFloat(goal))
                    .frame(width: 130, height: 130)
                
                VStack(spacing: 4) {
                    Text(emoji)
                        .font(.largeTitle)
                    
                    Text("\(value) / \(goal) \(unit)")
                        .font(.caption)
                        .bold()
                    
                    Button(action: { isEditing.wrappedValue = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                    }
                }
            }
            
            Text(title)
                .font(.headline)
        }
        .sheet(isPresented: isEditing) {
            GoalEditView(title: "Ändra veckans mål för \(title.lowercased())", goal: isEditing.wrappedValue ? Binding(get: { goal }, set: { _ in }) : .constant(goal), onSave: editAction)
        }
    }
    
    private func loadChildren() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("children").getDocuments { snapshot, _ in
            let fetched = snapshot?.documents.compactMap { doc -> Child? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let avatar = data["avatar"] as? String else { return nil }
                let balance = data["balance"] as? Int ?? 0
                let savings = data["savings"] as? Int ?? 0
                let weeklyGoal = data["weeklyGoal"] as? Int ?? 50
                let weeklyScreenGoal = data["weeklyScreenTimeGoal"] as? Int ?? 30
                
                return Child(id: doc.documentID, name: name, avatar: avatar, balance: balance, savings: savings, weeklyGoal: weeklyGoal, weeklyScreenTimeGoal: weeklyScreenGoal)
            } ?? []
            
            DispatchQueue.main.async {
                self.children = fetched
                if self.selectedChild == nil, let first = fetched.first {
                    self.selectedChild = first
                }
            }
        }
    }
    
    private func updateChildBalance() {
        guard let userId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("children").document(child.id).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                let newBalance = data["balance"] as? Int ?? 0
                let newGoal = data["weeklyGoal"] as? Int ?? 50
                let newSavings = data["savings"] as? Int ?? 0
                let newScreenGoal = data["weeklyScreenTimeGoal"] as? Int ?? 30
                
                DispatchQueue.main.async {
                    self.selectedChild = Child(id: child.id, name: child.name, avatar: child.avatar, balance: newBalance, savings: newSavings, weeklyGoal: newGoal, weeklyScreenTimeGoal: newScreenGoal)
                }
            }
        }
    }
    
    private func updateChildProgress() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(child.id)
        
        childRef.collection("chores").getDocuments { snapshot, _ in
            let fetched = snapshot?.documents.compactMap { try? $0.data(as: Chore.self) } ?? []
            var totalMoney = 0
            var totalScreenTime = 0
            
            for chore in fetched {
                let completedCount = chore.completed
                let reward = chore.value
                
                if chore.rewardType == "money" {
                    totalMoney += completedCount * reward
                } else if chore.rewardType == "screenTime" {
                    totalScreenTime += completedCount * reward
                }
            }
            
            DispatchQueue.main.async {
                self.moneyEarned = totalMoney
                self.screenTimeEarned = totalScreenTime
                self.weeklyMoneyGoal = child.weeklyGoal
                self.weeklyScreenTimeGoal = child.weeklyScreenTimeGoal ?? 30
            }
        }
    }
    
    private func saveMoneyGoal() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").document(child.id).updateData(["weeklyGoal": weeklyMoneyGoal])
    }
    
    private func saveScreenTimeGoal() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").document(child.id).updateData(["weeklyScreenTimeGoal": weeklyScreenTimeGoal])
    }
    
    private func addMissingSavingsField() {
        guard let userId = authService.user?.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("children").getDocuments { snapshot, _ in
            for doc in snapshot?.documents ?? [] {
                let ref = db.collection("users").document(userId).collection("children").document(doc.documentID)
                if doc.data()["savings"] == nil {
                    ref.updateData(["savings": 0])
                }
            }
        }
    }
}
