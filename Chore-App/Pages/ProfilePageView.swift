import SwiftUI

//shows profile with avatar and added chores

struct ProfilePageView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
                .padding()
            
            Text("Chores List")
                .font(.largeTitle)
                .padding()
            
            
            PrimaryButton(title: "Logout", action: authService.logout)
                 .padding()
         }
        }
    }

