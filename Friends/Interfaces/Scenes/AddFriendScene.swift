import SwiftUI

struct AddFriendScene: View {
    
    @EnvironmentObject private var friendService: FriendService
    
    @State private var username = ""
    @State private var error: Error?
    
    var body: some View {
        Form {
            if let error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
            }
            TextField("Username", text: $username)
            Button("Add friend") {
                Task {
                    try await friendService.sendFriendRequest(to: username)
                }
            }
        }
    }
    
    private func runSafeAsyncAction(action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
                self.error = nil
            } catch {
                self.error = error
            }
        }
    }
}
