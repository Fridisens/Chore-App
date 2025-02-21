import SwiftUI
import Firebase

struct ContentView: View {
    
    @EnvironmentObject var authService: AuthService
    @StateObject var choreViewModel = ChoreViewModel()
        
        
        
    var body: some View {
        if authService.user == nil {
            LoginView()
        } else {
            ContentView()
                
            }
    }
}

#Preview {
    ContentView()
}
