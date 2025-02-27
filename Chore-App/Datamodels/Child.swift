import Foundation

struct Child: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var avatar: String
    var balance: Int
}
