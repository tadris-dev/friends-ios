import Foundation

@MainActor
class FriendsAppState: ObservableObject {
    
    @Published var friends: [Friend] = []
    
    init(friends: [Friend]) {
        self.friends = friends
    }
    
    #if DEBUG
    
    static let previewInstance = FriendsAppState(friends: Friend.exampleFriends)
    
    #endif
}
