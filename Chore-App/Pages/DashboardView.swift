//Dashboard with progress bars for money and screen time
import SwiftUI


struct DashboardView: View {
    
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome, \(authService.user?.name ?? "User")!")
                    .font(.largeTitle)
                    .padding()
                
                Text("Your balance: \(authService.user?.balance ?? 0)")
                    .font(.title2)
                    .padding()
                
                
                NavigationButton(title: "Add Chores or Task", destination: AddItemView())
                
            }
            .padding()
        }
    }
}
