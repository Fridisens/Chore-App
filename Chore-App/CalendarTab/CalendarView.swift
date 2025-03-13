import SwiftUI

//View calendar and days are green or red depends on done or not




import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            Text("Kalender")
                .font(.largeTitle)
                .foregroundColor(.purple)
                .padding()
            
            DatePicker("Välj datum", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .accentColor(.purple)
                .padding()
        }
        .padding()
    }
}
