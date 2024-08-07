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
    func register(with alias: String) -> some Publisher<UUID, Swift.Error> {
        let params = RegisterRequestParameters(aliasHash: HashingHelper.sha256(for: alias), publicKey: [1, 23])
        return httpClient.request(from: .user, method: .post, parameters: params)
            .tryMap { [weak self] (response: RegisterRequestResponse) in
                guard let uuid = UUID(uuidString: response.uuid) else { throw SessionManagement.Error.processingFailed }
                self?.alias = alias
                return uuid
            }
    }
    
    // TODO: Send actual challenge
    func login() -> some Publisher<UUID, Swift.Error> {
        guard let alias else { return Fail(error: SessionManagement.Error.notRegistered).eraseToAnyPublisher() }
        let params = LoginRequestParameters(aliasHash: HashingHelper.sha256(for: alias), challenge: [1, 23])
        return httpClient.request(from: .session, method: .post, parameters: params)
            .tryMap { [weak self] (response: RegisterRequestResponse) in
                guard let uuid = UUID(uuidString: response.uuid) else { throw SessionManagement.Error.processingFailed }
                self?.alias = alias
                return uuid
            }
            .eraseToAnyPublisher()
    }
    
    enum Error: Swift.Error, LocalizedError {
        case processingFailed
        case notRegistered
    }
}

// MARK: - Types

fileprivate struct RegisterRequestParameters: Encodable {
    let aliasHash: String
    let publicKey: [UInt8]
}

fileprivate struct RegisterRequestResponse: Decodable {
    let uuid: String
}

fileprivate struct LoginRequestParameters: Encodable {
    let aliasHash: String
    let challenge: [UInt8]
}
