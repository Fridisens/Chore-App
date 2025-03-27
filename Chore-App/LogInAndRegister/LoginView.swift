import SwiftUI
import FirebaseAuth
import Firebase


struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 20) {

            VStack(spacing: 15) {
                CustomTextField(placeholder: "E-post", text: $email, isSecure: false)
                CustomTextField(placeholder: "Lösenord", text: $password, isSecure: true)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }

            PrimaryButton(title: "Logga in") {
                authService.login(email: email, password: password) { result in
                    switch result {
                    case .success():
                        print("Log in success")
                    case .failure(let error):
                        if let err = error as NSError?,
                           let code = AuthErrorCode(rawValue: err.code),
                           code == .wrongPassword {
                            self.errorMessage = "Felaktig e-mail adress eller lösenord, försök igen."
                        } else {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }

            Divider()
                .padding(.vertical, 10)

            Text("Eller logga in med")
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack(spacing: 20) {
                Button(action: {
                    print("Google login (placeholder)")
                }) {
                    HStack {
                        Image("google.logo")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Google")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }

                Button(action: {
                    print("Apple login (placeholder)")
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        Text("Apple")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(10)
                }
            }

            Button(action: {
                print("Glömt lösenord tryckt")
            }) {
                Text("Glömt lösenord?")
                    .font(.footnote)
                    .foregroundColor(.purple)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }
}
