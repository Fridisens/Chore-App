//Dashboard with progress bars for money and screen time
import SwiftUI


struct DashboardView: View {
    
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            Text("Welcome, \(authService.user?.name ?? "User")!")
                .font(.largeTitle)
                .padding()
            
            Text("Your balance: \(authService.user?.balance ?? 0)")
                .font(.title2)
                .padding()
            
            Button(action: {
                authService.logout()
            }) {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
            }
            
            .padding()
        }
        
        .padding()
    }
}
