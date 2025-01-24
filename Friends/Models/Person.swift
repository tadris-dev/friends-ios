import Foundation

protocol Person: Hashable, Identifiable {
    
    var userId: String { get }
    var name: String { get }
    var avatarUrl: URL? { get }
}

extension Person {
    
    var id: String { return userId }
    var initial: String {
        guard let firstLetter = name.first else { return "?" }
        return String(firstLetter)
    }
}
