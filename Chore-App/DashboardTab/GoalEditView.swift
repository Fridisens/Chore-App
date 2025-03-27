import SwiftUI

struct GoalEditView: View {
    var title: String
    @Binding var goal: Int
    var onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text(title)
                    .font(.headline)
                    .padding()
                
                TextField("Ange nytt mål", value: $goal, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .padding()
                
                Button("Spara") {
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}
