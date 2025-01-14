import Combine
import SwiftUI
import Foundation
import OSLog

@MainActor
class FriendsAppState: ObservableObject {
    
    private let locationService: LocationService
    private let httpClient: HTTPClient
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var profile = Friend(name: "You", location: .init(latitude: 0, longitude: 0))
    @Published var friends: [Friend] = []
    
    var currentLocation: Location? { locationService.currentLocation }
    
    init(friends: [Friend]) {
        self.friends = friends
        let userID = if let uuidString = UserDefaults.standard.string(forKey: "userID"), let uuid = UUID(uuidString: uuidString) {
            uuid
        } else {
            UUID()
        }
        // self.userID = userID
        self.locationService = LocationService()
        self.httpClient = HTTPClient()
        
        Task {
            do {
                try await locationService.requestAuthorization()
            } catch {
                // TODO: Show error in user interface
            }
        }
    }
    
    #if DEBUG
    
    static let previewInstance = FriendsAppState(friends: Friend.exampleFriends)
    
    #endif
}
