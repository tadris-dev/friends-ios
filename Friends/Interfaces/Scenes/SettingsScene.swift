import SwiftUI

struct SettingsScene: View {
    
    @EnvironmentObject private var sessionManagement: SessionManagement
    
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
            Button("Logout") {
                Task {
                    try await sessionManagement.logout()
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
                print(error)
                self.error = error
            }
        }
    }
}
