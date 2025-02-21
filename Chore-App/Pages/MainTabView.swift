import SwiftUI


struct MainTabView: View {
    
    var body: some View {
        
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
