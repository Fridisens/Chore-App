import SwiftUI
import Firebase
import FirebaseAuth

struct AddChoreView: View {
    @State private var name = ""
    @State private var value: Int = 10
    @State private var selectedRewardType = "money"
    @State private var selectedDays: [String] = []
    @State private var selectedIcon: String = "star.fill"

    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService

    var selectedChild: Child
    let weekdays = ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]
    let availableIcons = ["star.fill", "leaf.fill", "house.fill", "gamecontroller.fill", "flame.fill", "heart.fill", "magazine.fill", "sparkles", "bolt.fill", "camera.fill", "paintbrush.fill", "hammer.fill", "shower.fill", "washer.fill", "car.fill","dog.fill", "cat.fill", "party.popper.fill"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Syssla")) {
                    TextField("Namn på sysslan", text: $name)
                        .autocapitalization(.sentences)

                    ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 30))
                                            .padding()
                                            .background(selectedIcon == icon ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == icon ? Color.purple : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                Section(header: Text("Belöning")) {
                    Stepper("Värde: \(value) \(selectedRewardType == "money" ? "kr" : "min")", value: $value, in: 1...100)
                        .padding(.vertical, 5)

                    HStack(spacing: 50) {
                        ForEach(["money", "screenTime"], id: \.self) { type in
                            Button(action: {
                                selectedRewardType = type
                            }) {
                                VStack {
                                    Image(systemName: type == "money" ? "dollarsign.circle.fill" : "tv.fill")
                                        .font(.system(size: 35))
                                        .foregroundColor(selectedRewardType == type ? .purple : .gray)

                                    Text(type == "money" ? "Pengar" : "Skärmtid")
                                        .font(.caption)
                                        .foregroundColor(selectedRewardType == type ? .purple : .gray)
                                }
                                .padding(8)
                                .background(selectedRewardType == type ? Color.purple.opacity(0.1) : Color.clear)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }

                Section(header: Text("Välj dagar")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(weekdays, id: \.self) { day in
                            Button(action: {
                                if selectedDays.contains(day) {
                                    selectedDays.removeAll { $0 == day }
                                } else {
                                    selectedDays.append(day)
                                }
                            }) {
                                Text(String(day.prefix(1)))
                                    .font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(selectedDays.contains(day) ? Color.purple : Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(selectedDays.contains(day) ? 0 : 1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 5)
                }

                Section {
                    Button(action: saveChore) {
                        Text("Spara Syssla")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty ? Color.gray.opacity(0.5) : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("")
        }
    }

    private func saveChore() {
        guard let parentId = authService.user?.id else { return }

        let newChore = Chore(
            id: UUID().uuidString,
            name: name,
            value: value,
            completed: 0,
            assignedBy: parentId,
            rewardType: selectedRewardType,
            days: selectedDays,
            frequency: selectedDays.count,
            completedDates: [:],
            icon: selectedIcon
        )

        firestoreService.addChore(for: parentId, childId: selectedChild.id, chore: newChore) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Fel vid sparande: \(error.localizedDescription)")
            }
        }
    }
}
