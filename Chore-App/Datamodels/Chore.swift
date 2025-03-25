import Foundation

struct Chore: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var value: Int
    var completed: Int
    var assignedBy: String
    var rewardType: String
    var days: [String]
    var frequency: Int?
    var completedDates: [String: Bool]?
    
    init(id: String, name: String, value: Int = 0, completed: Int, assignedBy: String, rewardType: String, days: [String], frequency: Int? = nil, completedDates: [String: Bool]? = nil) {
        self.id = id
        self.name = name
        self.value = value
        self.completed = completed
        self.assignedBy = assignedBy
        self.rewardType = rewardType
        self.days = days
        self.frequency = frequency
        self.completedDates = completedDates
    }
}
