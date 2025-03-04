import SwiftUI
import Firebase
import FirebaseAuth

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
    @State private var isShowingLogoutAlert = false
    @State private var isShowingPasswordSheet = false
    @State private var password = ""
    @State private var showConfetti = 0
    
    var body: some View {
            NavigationView {
                VStack {
                    ChildPickerView(selectedChild: $selectedChild, children: children)
                        .padding()

                    if let child = selectedChild {
                        VStack {
                            Image(child.avatar)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.purple, lineWidth: 3))

                            Text(child.name)
                                .font(.title)
                        }
                        .padding(.bottom)

                        AvatarPicker(selectedAvatar: $selectedAvatar, onAvatarSelected: saveAvatarToFirebase)
                            .padding()

                        ChoreListView(
                            chores: chores,
                            completedChores: $completedChores,
                            selectedChild: child,
                            onEdit: { chore in
                                print("Tryckt på redigera för: \(chore.name)")
                                selectedChore = chore
                            }
                        )
                        .confettiCannon(trigger: $showConfetti)
                        
                        Spacer()
                    }
                }
                .onChange(of: selectedChore) { oldValue, newValue in
                    if let chore = newValue {
                        print("Redigerar syssla: \(chore.name)")
                        isEditingChore = true
                    } else {
                        print("Ingen syssla vald")
                    }
                }

                
                
                .navigationTitle("")
                .navigationBarItems(trailing:
                    Button(action: { isAddingChild = true }) {
                        Image(systemName: "person.fill.badge.plus")
                            .foregroundColor(.purple)
                            .font(.title)
                    }
                )
                .sheet(isPresented: $isAddingChild) {
                    AddChildView(onChildAdded: loadChildren, isAddingChild: $isAddingChild)
                }
                
                .sheet(isPresented: $isEditingChore) {
                                if let chore = selectedChore {
                                    EditChoreView(chore: chore, onSave: updateChore)
                                        .onAppear {
                                            print("✅ Öppnar redigeringsvy för: \(chore.name)")
                                        }
                                } else {
                                    Text("Något gick fel! Ingen syssla vald.")
                                        .onAppear {
                                            print("Ingen syssla vald vid öppning!")
                                        }
                                }
                            }


                
                .onAppear {
                    loadChildren()
                    loadAvatarFromFirebase()
                }
            }
        }
    
    
    private func updateChore(_ chore: Chore) {
            guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
            
            let db = Firestore.firestore()
            let choreRef = db.collection("users").document(parentId).collection("children").document(childId).collection("chores").document(chore.id)
            
            do {
                try choreRef.setData(from: chore) { error in
                    if let error = error {
                        print("Error updating chore: \(error.localizedDescription)")
                    } else {
                        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
                            chores[index] = chore
                        }
                    }
                }
            } catch {
                print("Error encoding chore: \(error.localizedDescription)")
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
    
    private func deleteChore(_ chore: Chore) {
        guard let parentId = authService.user?.id, let childId = selectedChild?.id else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(parentId).collection("children").document(childId).collection("chores").document(chore.id).delete { error in
            if let error = error {
                print("Error deleting chore: \(error.localizedDescription)")
            } else {
                print("Chore deleted successfully")
                DispatchQueue.main.async {
                    self.chores.removeAll { $0.id == chore.id }
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

