import SwiftUI

//View calendar and days are green or red depends on done or not




struct CalendarView: View {
    
    @State private var selectedDate = Date()
    
    
    var body: some View {
        VStack {
            Text("Kalender")
                .font(.largeTitle)
                .padding()
            
            DatePicker("Välj datum", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
        }
        .padding()
    }
}
