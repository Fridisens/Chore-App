import SwiftUI

struct AddItemView: View {
    var selectedChild: Child
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = "Chore"

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple.opacity(0.7))
                        .padding()
                }
            }

            Text("Vad vill du lägga till?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.purple)

            HStack(spacing: 0) {
                tabButton(title: "Syssla", tag: "Chore")
                tabButton(title: "Uppgift", tag: "Task")
            }
            .frame(height: 44)
            .background(Color.gray.opacity(0.1))
            .clipShape(Capsule())
            .padding(.horizontal)

            ZStack {
                if selectedTab == "Chore" {
                    AddChoreView(selectedChild: selectedChild)
                        .transition(.opacity)
                }

                if selectedTab == "Task" {
                    AddTaskView(selectedChild: selectedChild)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: selectedTab)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }

    private func tabButton(title: String, tag: String) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tag
            }
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(selectedTab == tag ? .white : .purple)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selectedTab == tag ? Color.purple : Color.clear)
                .clipShape(Capsule())
        }
    }
}
