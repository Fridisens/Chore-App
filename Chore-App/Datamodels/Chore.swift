import Foundation

struct Chore: Identifiable, Codable {
    var id: String
    var name: String
    var value: Int
    var completed: Int
    var assignedBy: String
    var rewardType: String
    var days: [String]
    var frequency: Int?
    
    init(id: String, name: String, completed: Int, assignedBy: String, rewardType: String, days: [String], frequency: Int? = nil) {
        self.id = id
        self.name = name
        self.value = 0
        self.completed = completed
        self.assignedBy = assignedBy
        self.rewardType = rewardType
        self.days = days
        self.frequency = frequency ?? 1
    }
}
