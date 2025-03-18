import Foundation

struct Task: Identifiable, Codable {
    var id: String
    var name: String
    var time: String
    var duration: Int? // time in minutes
    var date: String? // Date for one time tasks
    var days: [String] // Days for  reccuring tasks
    var type: String // "oneTime" eller "recurring"
    var repeatOption: String // "Never", "Daily", "Every week", etc.
    var completed: Int
    var assignedBy: String
}
