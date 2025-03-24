import SwiftUI

struct EditChoreView: View {
    @Binding var chore: Chore  // ✅ Korrekt Binding till sysslan
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Redigera syssla")
                .font(.title)
                .padding()

            // ✅ Textfält för namn
            TextField("Namn", text: $chore.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()

            // ✅ Numeriskt fält för värde
            TextField("Värde", value: $chore.value, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .padding()

            // ✅ Spara-knapp
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
