import Combine
import Foundation

class KeyUpdateService {
    
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func updateKeys(_ keys: [UpdateKeysEntry]) async throws {
        let params = UpdateKeysRequest(keys: keys)
        try await httpClient.sendRequest(to: .keys, parameters: params)
    }
    
    struct UpdateKeysRequest: Encodable {
        let keys: [UpdateKeysEntry]
    }

    struct UpdateKeysEntry: Encodable {
        let to: UUID
        let key: String
    }
}
