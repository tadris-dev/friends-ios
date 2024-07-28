import SwiftUI
import CoreLocation

@main
struct FriendsApp: App {
    
    @ObservedObject private var appState = FriendsAppState(friends: Friend.exampleFriends)
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator()
                .environmentObject(appState)
        }
    }
}
