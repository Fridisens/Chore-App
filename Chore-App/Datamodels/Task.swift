import Foundation

struct Task: Identifiable, Codable {
    var id: String
    var name: String
    var time: String
    var duration: Int?
    var date: String?
    var days: [String]
    var type: String
    var repeatOption: String
    var completed: Int
    var assignedBy: String
}
