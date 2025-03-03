import Foundation

struct Task: Identifiable, Codable {
    var id: String
    var name: String
    var assignedBy: String
    var days: [String]
    var frequency: Int
    var completed: Int
    
}
