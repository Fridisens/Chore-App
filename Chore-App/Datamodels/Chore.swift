import Foundation

struct Chore: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var value: Int
    var frequency: Int
    var completed: Int
    var assignedBy: String
}
