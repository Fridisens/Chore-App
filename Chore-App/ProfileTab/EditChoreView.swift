import SwiftUI


struct EditChoreView: View {
    @State var chore: Chore
    var onSave: (Chore) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Redigera syssla")
                .font(.title)
                .padding()

            TextField("Namn", text: $chore.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Värde", value: $chore.value, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()

            Button("Spara") {
                onSave(chore)
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
