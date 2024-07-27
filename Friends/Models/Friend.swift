import CoreLocation
import Foundation

struct Friend: Identifiable, Hashable {
    
    let id: UUID
    let name: String
    let location: Location
    
    var initial: String {
        guard let firstLetter = name.first else { return "?" }
        return String(firstLetter)
    }
    
    init(name: String, location: Location) {
        self.id = UUID()
        self.name = name
        self.location = location
    }
    
    #if DEBUG
    static let exampleFriends: [Friend] = [
        Friend(name: "Tim", location: .init(latitude: 52.5, longitude: 13.3)),
        Friend(name: "Jannis", location: .init(latitude: 52.4, longitude: 13.5)),
        Friend(name: "Adrian", location: .init(latitude: 52.55, longitude: 13.4)),
    ]
    #endif
}
