import SwiftUI
import Firebase
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var moneyEarned: Int = 0
    @State private var screenTimeEarned: Int = 0
    @State private var isShowingAddItemView = false
    @State private var weeklyGoal: Int = 50
    
    var body: some View {
        VStack {
            
            ChildPickerView(selectedChild: $selectedChild, children: children) {
                isShowingAddItemView = true
            }
            .padding()
            
            if let child = selectedChild {
                VStack {
                    Text("Välkommen, \(authService.user?.name ?? "User")!")
                        .font(.largeTitle)
                        .padding(.bottom, 10)
                    
                    
                    HStack(spacing: 40) {
                        VStack {
                            ProgressRing(progress: CGFloat(moneyEarned) / CGFloat(weeklyGoal))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack {
                                        Text("\(moneyEarned) / \(weeklyGoal) SEK")
                                            .font(.caption)
                                            .bold()
                                    }
                                )
                            Text("Intjänade pengar")
                                .font(.headline)
                        }
                        
                        VStack {
                            ProgressRing(progress: CGFloat(screenTimeEarned) / CGFloat(weeklyGoal))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack {
                                        Text("\(screenTimeEarned) / \(weeklyGoal) min")
                                            .font(.caption)
                                            .bold()
                                    }
                                )
                            Text("Skärmtid")
                                .font(.headline)
                        }
                    }
                    .padding()
                    
                    HStack {
                        Text("Veckans mål:")
                            .font(.headline)
                        
                        TextField("Mål", value: $weeklyGoal, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        
                        Button("Spara") {
                            saveWeeklyGoal()
                        }
                        .padding(8)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    
                    Button(action: {
                        isShowingAddItemView = true
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
                    .sheet(isPresented: $isShowingAddItemView) {
                        AddItemView(selectedChild: child)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadChildren()
            updateChildProgress()
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
                    print("Saknade fält i dokumentet: \(data)")
                    return nil
                }
                
                return Child(id: doc.documentID, name: name, avatar: avatar, balance: balance, weeklyGoal: weeklyGoal)
            } ?? []
            
            if selectedChild == nil, !children.isEmpty {
                selectedChild = children.first
                weeklyGoal = selectedChild?.weeklyGoal ?? 50
            }
        }
    }
    
    private func updateChildProgress() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").document(child.id).collection("chores")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Fel vid hämtning av sysslor: \(error.localizedDescription)")
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
    
    private func saveWeeklyGoal() {
        guard let parentId = authService.user?.id, let child = selectedChild else { return }
        
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document(child.id)
        
        childRef.updateData(["weeklyGoal": weeklyGoal]) { error in
            if let error = error {
                print("Fel vid uppdatering av veckomål: \(error.localizedDescription)")
            } else {
                print("Veckomål uppdaterat till \(weeklyGoal) SEK")
            }
        }
    }
    
    private func listenToChildBalance(childId: String) {
        guard let parentId = authService.user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(parentId).collection("children").document(childId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Fel vid uppdatering av saldo: \(error.localizedDescription)")
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
                        print("Uppdaterat saldo: \(balance) kr")
                    }
                }
            }
    }
}
