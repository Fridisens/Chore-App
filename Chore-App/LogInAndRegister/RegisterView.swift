import SwiftUI



struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            inputFields()
            registerButton()
        }
        .padding()
    }
    
    
    private func inputFields() -> some View {
        VStack {
            TextField("Namn", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()
            
            TextField("E-post", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()
            
            SecureField("Lösenord", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    
    private func registerButton() -> some View {
        PrimaryButton(title: "Registrera", action: registerUser)
            .padding()
    }
    
    private func registerUser() {
        authService.registerUser(email: email, password: password, name: name) { (result: Result<User, Error>) in
            switch result {
            case .success(let user):
                print("Account created for: \(user.name)")
                
                self.name = ""
                self.email = ""
                self.password = ""
                self.errorMessage = ""
                
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
