import Foundation

struct Task: Identifiable, Codable {
    var id: String
    var name: String
    var startTime: Date?
    var endTime: Date?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool
    var date: Date?
    var type: String
    var repeatOption: String
    var completed: Int
    var assignedBy: String
    var icon: String
}
