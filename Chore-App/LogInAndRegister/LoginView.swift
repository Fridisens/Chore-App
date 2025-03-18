import SwiftUI



struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
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
            
            PrimaryButton(title: "Logga in") {
                authService.login(email: email, password: password) { result in
                    switch result {
                    case .success():
                        print("log in success")
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .padding()
    }
}
