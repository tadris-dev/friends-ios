import SwiftUI
import CoreLocation
import SwiftData

@main
struct FriendsApp: App {
    
    @ObservedObject private var appState: FriendsAppState
    // @State private var context: ModelContext?
    
    var body: some Scene {
        WindowGroup {
            DebugView()
                .environmentObject(appState)
            //if let context {
            //    MainCoordinator()
            //        .environmentObject(appState)
            //        .modelContext(context)
            //} else {
            //    Text("Failed to initialise database")
            //}
        }
    }
    
    init() {
        // let container = try? ModelContainer(for: LocationSample.self, configurations: .init(for: LocationSample.self))
        // let context: ModelContext? = if let container { ModelContext(container) } else { nil }
        // self.context = context
        self.appState = FriendsAppState(friends: Friend.exampleFriends)
    }
}

@Model
class LocationSample {
    
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
