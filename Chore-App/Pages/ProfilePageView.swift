import SwiftUI
import Firebase
import FirebaseAuth

struct ProfilePageView: View {
    @EnvironmentObject var authService: AuthService
    @State private var children: [Child] = []
    @State private var selectedChild: Child?
    @State private var chores: [Chore] = []
    @State private var completedChores: [String] = []
    @State private var isAddingChild = false
    @State private var selectedAvatar: String = "avatar1"
    @State private var isShowingDeleteAlert = false
    @State private var password = ""
    
    var body: some View {
        
        VStack(alignment: .center) {
            
            Picker("Välj barn", selection: $selectedChild) {
                ForEach(children, id: \.self) { child in
                    Text(child.name).tag(Optional(child))
                }
            }
            
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            if let child = selectedChild {
                
                
                VStack {
                    Image(child.avatar)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.purple, lineWidth: 3))
                        .padding(.top)
                    
                    Text(child.name)
                        .font(.title)
                        .padding(.bottom, 10)
                }
            }
            
            AvatarPicker(selectedAvatar: $selectedAvatar, onAvatarSelected: saveAvatarToFirebase)
                .padding()
            
            List {
                if let child = selectedChild {
                    Section(header: Text("Dagens sysslor")) {
                        ForEach(chores.filter { $0.frequency == 1 }) { chore in
                            ChoreRow(chore: chore, completedChores: $completedChores, selectedChild: child)
                        }
                    }
                    
                    Section(header: Text("Veckans sysslor")) {
                        ForEach(chores.filter { $0.frequency > 1 }) { chore in
                            ChoreRow(chore: chore, completedChores: $completedChores, selectedChild: child)
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                if selectedChild != nil {
                    Button(action: {
                        isShowingDeleteAlert = true
                    }) {
                        Text("Ta bort barn")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                Button(action: logout) {
                    Text("Logga ut")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
            
        }
        .navigationTitle("Profile")
        .navigationBarItems(trailing:
                                Button(action: {
            isAddingChild = true
        }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.purple)
                .font(.title)
        }
        )
        .sheet(isPresented: $isAddingChild) {
            AddChildView(onChildAdded: loadChildren, isAddingChild: $isAddingChild)
        }
        
        .alert("Skriv ditt lösenord för att godkänna borttagning", isPresented: $isShowingDeleteAlert) {
            SecureField("Lösenord", text: $password)
            Button("Ta bort", role: .destructive) {
                deleteChild()
            }
            Button("Tillbaka", role: .cancel) {}
        }
        .onAppear {
            loadChildren()
            loadAvatarFromFirebase()
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
                loadChores()
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
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            authService.user = nil
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
    
    
    private func addChild(name: String) {
        guard let parentId = authService.user?.id, !name.isEmpty else { return }
        let db = Firestore.firestore()
        let childRef = db.collection("users").document(parentId).collection("children").document()
        
        let newChild = Child(id: childRef.documentID, name: name, avatar: "avatar1", balance: 0)
        
        do {
            try childRef.setData(from: newChild) { error in
                if let error = error {
                    print("Error adding child: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.children.append(newChild)
                        self.selectedChild = newChild
                        self.loadChores()
                    }
                }
            }
        } catch {
            print("Error encoding child: \(error.localizedDescription)")
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
        
        let credential = EmailAuthProvider.credential(withEmail: authService.user?.email ?? "", password: password)
        
        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
            if let error = error {
                print("Error re-authenticating: \(error.localizedDescription)")
                return
            }
            
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
    }
}




