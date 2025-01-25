import SwiftUI

struct LoginScene: View {
    
    @EnvironmentObject private var sessionManagement: SessionManagement
    
    @State private var error: Error? = nil
    @State private var isLoading = false
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        Form {
            if let error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
            Section("Server Configuration") {
                LabeledTextField("Server", value: $sessionManagement.server)
                Button("Reconfigure Server") {
                    runSafeAsyncAction {
                        try await sessionManagement.changeServer()
                    }
                }
                .disabled(isLoading)
            }
            Section("Login") {
                LabeledTextField("Username", value: $username)
                LabeledTextField("Password", value: $password)
                    .textContentType(.password)
                Button("Login") {
                    runSafeAsyncAction {
                        try await sessionManagement.login(username: username, password: password)
                    }
                }
                .disabled(isLoading)
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
