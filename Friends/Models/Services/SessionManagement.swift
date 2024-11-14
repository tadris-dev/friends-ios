import Combine
import Foundation
import CryptoKit

class SessionManagement {
    
    private let httpClient: HTTPClient
    
    private var alias: String?
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    // TODO: Send actual public key
    func register(with alias: String) async throws -> UUID {
        let params = RegisterRequestParameters(aliasHash: HashingHelper.sha256(for: alias), publicKey: "123")
        let response: RegisterRequestResponse = try await httpClient.sendRequest(to: .user, parameters: params)
        guard let uuid = UUID(uuidString: response.uuid) else { throw SessionManagement.Error.processingFailed }
        self.alias = alias
        return uuid
    }
    
    // TODO: Send actual challenge
    func login(with alias: String) async throws -> UUID {
        let params = LoginRequestParameters(aliasHash: HashingHelper.sha256(for: alias), challenge: "123")
        let response: RegisterRequestResponse = try await httpClient.sendRequest(to: .session, parameters: params)
        guard let uuid = UUID(uuidString: response.uuid) else { throw SessionManagement.Error.processingFailed }
        return uuid
    }
    
    // TODO: Implement logout
    
    // MARK: - Types
    
    enum Error: Swift.Error, LocalizedError {
        case processingFailed
        case notRegistered
    }

    fileprivate struct RegisterRequestParameters: Encodable {
        let aliasHash: String
        let publicKey: String
    }

    fileprivate struct RegisterRequestResponse: Decodable {
        let uuid: String
    }

    fileprivate struct LoginRequestParameters: Encodable {
        let aliasHash: String
        let challenge: String
    }
}
