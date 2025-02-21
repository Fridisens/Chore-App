import Foundation

//Uppgift
struct Task: Identifiable, Codable {
    var id: String
    var name: String
    var assignedBy: String
    var days: [String] //monday and wednesday?
    var frequency: Int
    var completed: Int //done?
    
}
