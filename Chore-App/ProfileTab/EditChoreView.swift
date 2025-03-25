import SwiftUI

struct EditChoreView: View {
    @Binding var chore: Chore
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Redigera syssla")
                .font(.title)
                .padding()
            
            TextField("Namn", text: $chore.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()

      
            TextField("Värde", value: $chore.value, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()

         
            Button("Spara") {
                onSave()
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
