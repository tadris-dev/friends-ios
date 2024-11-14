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
                    TestItem("Register", action: appState.registerTest)
                    TestItem("Login", action: appState.loginTest)
                    TestItem("Initiate Handshake", action: appState.initiateHandshakeTest)
                    TestItem("Accept Handshake", action: appState.acceptHandshakeTest)
                    TestItem("Add Friend", action: appState.addFriendTest)
                    TestItem("Share Data", action: appState.shareDataTest)
                    TestItem("Query Data", action: appState.queryDataTest)
                }
                Section("Input / Results") {
                    LabelledTextField("Alias", value: $appState.alias)
                    LabelledText("UUID", value: appState.userID?.uuidString ?? "nil")
                    LabelledTextField("Friend UUID", value: $appState.friendUUIDString)
                    LabelledTextField("Shared Data", value: $appState.sharedData)
                    // LabelledText("Public Key", value: appState.userID?.uuidString ?? "nil")
                    // LabelledText("Private Key", value: appState.userID?.uuidString ?? "nil")
                    // NavigationLink("Show Friend Map") {
                    //     FriendsMapView(selectedFriend: .variable(nil))
                    //         .navigationTitle("Map")
                    // }
                }
            }
        }
    }
}

struct LabelledText: View {
    
    let label: String
    let value: String
    
    var body: some View {
        LabeledContent(label, value: value)
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Text("Copy")
                    Image(systemName: "doc.on.doc")
                }
            }
    }
    
    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }
}

struct LabelledTextField: View {
    
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
            TextField(label, text: $value).multilineTextAlignment(.trailing)
        }
    }
    
    init(_ label: String, value: Binding<String>) {
        self.label = label
        self._value = value
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
