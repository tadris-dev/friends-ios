import SwiftUI
import CoreLocation
import SwiftData

@main
struct FriendsApp: App {
    
    @ObservedObject private var appState: FriendsAppState
    // @State private var context: ModelContext?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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

#Preview {
    ContentView()
        .environmentObject(FriendsAppState.previewInstance)
}

struct ContentView: View {
    
    @EnvironmentObject var appState: FriendsAppState
    
    var body: some View {
        NavigationStack {
            List {
                Section("Tests") {
                    TestItem("Obtain Public Key", action: appState.obtainPublicKeyTest)
                    TestItem("Register", action: appState.registerTest)
                    TestItem("Login", action: appState.loginTest)
                    TestItem("Initiate Handshake", action: appState.initiateHandshakeTest)
                    TestItem("Accept Handshake", action: appState.acceptHandshakeTest)
                    TestItem("Add Friend Public Key", action: appState.addFriendPublicKeyTest)
                    TestItem("Add Friend", action: appState.addFriendTest)
                    TestItem("Share Data", action: appState.shareDataTest)
                    TestItem("Query Data", action: appState.queryDataTest)
                    TestItem("Decrypt Data", action: appState.decryptDataTest)
                }
                Section("User Data") {
                    LabeledTextField("Alias", value: $appState.alias)
                    LabeledText("UUID", value: appState.userID.uuidString)
                    LabeledText("Public Key", value: appState.publicKey)
                }
                Section("Friend Data") {
                    LabeledTextField("UUID", value: $appState.friendUUIDString)
                    LabeledTextField("Public Key", value: $appState.friendPublicKey)
                    LabeledText("Encrypted Session Key", value: appState.encryptedSessionKey)
                }
                Section("Results") {
                    LabeledTextField("Data To Send", value: $appState.dataToSend)
                    LabeledText("Data Received", value: appState.receivedData)
                    LabeledText("Decrypted Data Received", value: appState.decryptedData)
                    LabeledText("Session Key", value: appState.sessionKey)
                }
            }
        }
    }
}


struct TestItem: View {
    
    let name: String
    let action: () async -> Bool
    @State private var state: TestState = .run
    
    var content: some View {
        state.icon.foregroundStyle(state.color)
    }
    
    var body: some View {
        LabeledContent {
            if state == .run {
                Button(action: runTest) {
                    content
                }
            } else {
                content
            }
        } label: {
            Text(name)
        }
    }
    
    
    init(_ name: String, action: @escaping () async -> Bool) {
        self.name = name
        self.action = action
    }
    
    func runTest() {
        guard state == .run else { return }
        state = .running
        Task {
            let success = await action()
            state = success ? .success : .failure
        }
    }
    
    enum TestState {
        case run, running, success, failure
        
        var icon: Image {
            switch self {
            case .run: return Image(systemName: "play.circle")
            case .running: return Image(systemName: "clock")
            case .success: return Image(systemName: "checkmark.circle")
            case .failure: return Image(systemName: "xmark.circle")
            }
        }
        
        var color: Color {
            switch self {
            case .run: return .blue
            case .running: return .gray
            case .success: return .green
            case .failure: return .red
            }
        }
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
