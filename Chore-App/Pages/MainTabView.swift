import SwiftUI


struct MainTabView: View {
    @State private var selectedTab = 1
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        
        NavigationView {
            TabView(selection: $selectedTab) {
                CalendarView()
                    .tabItem {
                        Label("Kalender", systemImage: "calendar")
                    }
                    .tag(0)
                
                DashboardView()
                    .tabItem {
                        Label("Översikt", systemImage: "house")
                    }
                    .tag(1)
                
                ProfilePageView()
                    .tabItem{
                        Label("Profil", systemImage: "person.circle")
                    }
                    .tag(2)
                
            }
            
            .onAppear{
                if authService.user != nil {
                    selectedTab = 1
                }
            }
        }
    }
}
