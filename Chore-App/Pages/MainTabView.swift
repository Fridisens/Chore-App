import SwiftUI


struct MainTabView: View {
    init() {
        print("MainTabView laddades in")
    }
    
    var body: some View {
        NavigationView {
            TabView {
                CalendarView()
                    .tabItem {
                        Label("Kalender", systemImage: "calendar")
                    }
                DashboardView()
                    .tabItem {
                        Label("Översikt", systemImage: "house")
                    }
                
                ProfilePageView()
                    .tabItem{
                        Label("Profil", systemImage: "person.circle")
                    }
                
            }
        }
    }
}
