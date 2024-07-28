import Foundation

@MainActor
class FriendsAppState: ObservableObject {
    
    let locationService = LocationService()
    
    @Published var friends: [Friend] = []
    
    init(friends: [Friend]) {
        self.friends = friends
        
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
