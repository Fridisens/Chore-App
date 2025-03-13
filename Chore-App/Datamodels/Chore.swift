import Foundation

struct Chore: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var value: Int
    var completed: Int
    var assignedBy: String
    var rewardType: String
    var days: [String]
}
