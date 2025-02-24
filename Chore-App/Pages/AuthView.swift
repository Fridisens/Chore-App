import SwiftUI

struct AuthView: View {
    
    @State private var selectedTab = "Login"  // which tab is choosen
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            if authService.user != nil {
                withAnimation {
                    MainTabView()
                }
                
            } else {
                
                VStack {
                    Text("TaskTreasure")
                        .font(.largeTitle)
                        .padding()
                    
                    
                    Picker(selection: $selectedTab, label: Text("Auth Selection")) {
                        Text("Login").tag("Login")
                        Text("Register").tag("Register")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == "Login" {
                        LoginView()
                    } else {
                        RegisterView()
                    }
                }
                .padding()
            }
        }
    }
}
