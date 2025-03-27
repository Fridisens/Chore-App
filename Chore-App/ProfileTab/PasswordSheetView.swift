import SwiftUI


struct PasswordSheetView: View {
    @Binding var password: String
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack {
            Text("Skriv in lösenord för att ta bort sysslan")
                .font(.title2)
                .padding()
            
            SecureField("Lösenord", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()
                .keyboardType(.default)
            
            HStack {
                Button("Avbryt") {
                    onCancel()
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Ta bort") {
                    onConfirm()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }
}
