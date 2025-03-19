import SwiftUI

struct CalendarViewRepresentable: UIViewRepresentable {
    @Binding var selectedDate: Date
    var taskDates: Set<Date>

    func makeUIView(context: Context) -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return datePicker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = selectedDate
        uiView.tintColor = UIColor.purple
        uiView.reloadInputViews()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: CalendarViewRepresentable

        init(_ parent: CalendarViewRepresentable) {
            self.parent = parent
        }

        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.selectedDate = sender.date
        }
    }
}
