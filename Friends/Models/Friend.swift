import CoreLocation
import Foundation
import MatrixRustSDK

struct Friend: Person {
    
    let userId: String
    let name: String
    let avatarUrl: URL?
    let location: Location?
    
    init(userId: String, name: String, avatarUrl: URL?, location: Location? = nil) {
        self.userId = userId
        self.name = name
        self.avatarUrl = avatarUrl
        self.location = location
    }
}
