//Dashboard with progress bars for money and screen time
import SwiftUI
import Firebase
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var weeklyGoal: Int = 50
    
    var body: some View {
            VStack {
                Picker("Välj barn", selection: $selectedChild) {
                    ForEach(children, id: \.self) { child in
                        Text(child.name).tag(Optional(child))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: selectedChild) { oldValue, newValue in
                    if oldValue?.id != newValue?.id {
                        updateChildBalance()
                    }
                }
                
                Text("Välkommen, \(authService.user?.name ?? "User")!")
                    .font(.largeTitle)
                    .padding()
                
                
                if let child = selectedChild {
                    Text("\(child.name)'s saldo \(child.balance) SEK")
                        .font(.title2)
                        .padding()
                    
                    ProgressRing(progress: CGFloat(child.balance) / CGFloat(weeklyGoal))
                        .frame(width: 150, height: 150)
                        .padding()
                    
                    Text("\(child.balance) SEK / \(weeklyGoal) SEK")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    
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
