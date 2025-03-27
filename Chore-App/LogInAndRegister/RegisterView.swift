import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 20) {
            
            VStack(spacing: 15) {
                CustomTextField(placeholder: "Namn", text: $name, isSecure: false)
                CustomTextField(placeholder: "E-post", text: $email, isSecure: false)
                CustomTextField(placeholder: "Lösenord", text: $password, isSecure: true)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }

            PrimaryButton(title: "Registrera", action: registerUser)
            Spacer()
        }
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
