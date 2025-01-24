import SwiftUI
import MatrixRustSDK

class SessionManagement: ObservableObject {
    
    private let matrixClient: MatrixClient
    
    @Published var server: String = ""
    @Published var loginNeeded: Bool = false
    @Published var verificationNeeded: Bool = false
    
    init(matrixClient: MatrixClient) {
        self.matrixClient = matrixClient
        
        matrixClient.verificationStateHandler.statePublisher.receive(on: DispatchQueue.main).map { $0 != .verified }.assign(to: &$verificationNeeded)
        matrixClient.$homeserver.map { $0 ?? "" }.receive(on: DispatchQueue.main).assign(to: &$server)
    }
    
    func changeServer() async throws {
        try await matrixClient.reconfigureClient(for: server)
    }
    
    func login(username: String, password: String) async throws {
        try await matrixClient.login(username: username, password: password)
    }
    
    func logout() async throws {
        try await matrixClient.logout()
    }
}
