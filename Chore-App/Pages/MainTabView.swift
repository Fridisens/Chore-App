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
                        Label("Calendar", systemImage: "calendar")
                    }
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }
                
                ProfilePageView()
                    .tabItem{
                        Label("Profile", systemImage: "person.circle")
                    }
                
            }
        }
    }
}
