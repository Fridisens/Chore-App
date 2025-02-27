import Foundation

//syssla
struct Chore: Identifiable, Codable {
    var id: String
    var name: String
    var value: Int
    var frequency: Int
    var completed: Int
    var assignedBy: String
}
