import Combine
import Foundation

class HandshakeService {
    
    private let httpClient: HTTPClient
    private let sharedDataService: SharedDataService
    
    init(httpClient: HTTPClient, sharedDataService: SharedDataService) {
        self.httpClient = httpClient
        self.sharedDataService = sharedDataService
    }
    
    func initiateHandshake(with friendId: UUID) async throws {
        let params = HandshakePostRequest(friendId: friendId, encryptedSeed: "123")
        do {
            try await httpClient.sendRequest(to: .handshake, parameters: params)
        } catch (HTTPClient.Error.operationFailed(let errorCode)) where errorCode == 404 {
            throw Error.handshakePartnerNotFound
        }
    }
    
    func acceptHandshake() async throws -> UUID {
        guard let handShake = try await sharedDataService.query(category: .handshake).items.first else { throw Error.noHandshakeAvailable }
        // TODO: Check seed
        return handShake.from
    }
    
    enum Error: Swift.Error, LocalizedError {
        case handshakePartnerNotFound
        case noHandshakeAvailable
    }
}

// MARK: - Types

fileprivate struct HandshakePostRequest: Encodable {
    let friendId: UUID
    let encryptedSeed: String
}
