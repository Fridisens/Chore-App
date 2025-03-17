import Foundation

struct Task: Identifiable, Codable {
    var id: String
    var name: String
    var time: String
    var days: [String]
    var completed: Int
    var assignedBy: String
    
}
