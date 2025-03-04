import SwiftUI


struct ChildPickerView: View {
    @Binding var selectedChild: Child?
    var children: [Child]

    var body: some View {
        Picker("Välj barn", selection: $selectedChild) {
            ForEach(children, id: \.id) { child in
                Text(child.name).tag(Optional(child))
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}
