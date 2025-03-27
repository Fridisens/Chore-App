import SwiftUI

struct AuthView: View {
    @State private var selectedTab = "Login"
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            if authService.user != nil {
                withAnimation {
                    MainTabView()
                }
            } else {
                VStack(spacing: 20) {
                    Text("🏆 TaskTreasure")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.purple)
                        .padding(.top)
                    
                    Spacer(minLength: 10)
                    
                    // Tabbar
                    HStack(spacing: 0) {
                        tabButton(title: "Logga in", isSelected: selectedTab == "Login") {
                            withAnimation(.easeInOut) {
                                selectedTab = "Login"
                            }
                        }
                        
                        tabButton(title: "Registrera", isSelected: selectedTab == "Register") {
                            withAnimation(.easeInOut) {
                                selectedTab = "Register"
                            }
                        }
                    }
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    
                    // Växla vy med animation
                    ZStack {
                        if selectedTab == "Login" {
                            LoginView()
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        if selectedTab == "Register" {
                            RegisterView()
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.purple : Color.clear)
                .foregroundColor(isSelected ? .white : .purple)
                .clipShape(Capsule())
        }
    }
}
