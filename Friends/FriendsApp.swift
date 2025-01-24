import SwiftUI
import CoreLocation
import SwiftData

@main
struct FriendsApp: App {
    
    @ObservedObject private var appState: AppState
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator()
                .environmentObject(appState)
                .environmentObject(appState.sessionManagement)
                .environmentObject(appState.locationService)
                .environmentObject(appState.friendService)
        }
    }
    
    init() {
        self.appState = AppState()
    }
}

import MatrixRustSDK
import OSLog
import Combine

enum ClientProxyAction {
    case receivedSyncUpdate
    case receivedAuthError(isSoftLogout: Bool)
    case receivedDecryptionError(UnableToDecryptInfo)
    
    var isSyncUpdate: Bool {
        if case .receivedSyncUpdate = self {
            return true
        } else {
            return false
        }
    }
}

class ClientDecryptionErrorDelegate: UnableToDecryptDelegate {
    private let actionsSubject: PassthroughSubject<ClientProxyAction, Never>
    
    init(actionsSubject: PassthroughSubject<ClientProxyAction, Never>) {
        self.actionsSubject = actionsSubject
    }
    
    func onUtd(info: UnableToDecryptInfo) {
        actionsSubject.send(.receivedDecryptionError(info))
    }
}

/*
struct MatrixView: View {
    
    @ObservedObject private var client: MatrixClient = .init()
    
    var body: some View {
        NavigationStack {
            List {
                // Section("Tests") {
                //     TestItem("Start Sync Service", action: client.startSyncService)
                //     TestItem("Check Rooms Number", action: client.updateRooms)
                // }
                Section("Client") {
                    StatusItem("Client Ready", active: client.clientReady)
                    StatusItem("Room List Service Active", active: client.roomListServiceActive)
                }
                Section("User Data") {
                    LabeledText("Session Token", value: client.sessionToken)
                }
                Section("Rooms") {
                    ForEach(client.rooms, id: \.id) { room in
                        NavigationLink(room.displayName() ?? "Unknown Room") {
                            RoomView(room: room)
                        }
                    }
                }
            }
        }
    }
}
 */

struct RoomView: View {
    
    let room: RoomListItem
    @State private var isEncrypted: Bool? = nil
    
    var body: some View {
        List {
            LabeledText("ID", value: room.id())
            LabeledText("Is Direct", value: room.isDirect() ? "true" : "false")
            LabeledText("Is Encrypted", value: isEncrypted != nil ? (isEncrypted! ? "true" : "false") : "loading")
            Button("Accept Invite") {
                guard room.membership() == .invited else { return }
                Task {
                    try await room.invitedRoom().join()
                }
            }
        }
        .navigationTitle(Text(room.displayName() ?? "Unknown Room"))
        .task {
            self.isEncrypted = await room.isEncrypted()
        }
    }
    
    init(room: RoomListItem) {
        self.room = room
        self.isEncrypted = isEncrypted
    }
}

struct StatusItem: View {
    
    private let name: String
    private var active: Bool
    
    var body: some View {
        LabeledContent {
            if active {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        } label: {
            Text(name)
        }
    }
    
    
    init(_ name: String, active: Bool) {
        self.name = name
        self.active = active
    }
}

extension RoomListItem: @retroactive Identifiable {
    public var id: String {
        self.id()
    }
}
