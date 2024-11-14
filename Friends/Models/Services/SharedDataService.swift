import Foundation
import Combine

class SharedDataService {
    
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func query(category: SharedItemCategory) async throws -> SharedDataQueryResponse {
        return try await httpClient.sendRequest(to: .query(category))
    }
    
    func update(category: SharedItemCategory, data: String) async throws {
        guard category.isShared else { throw Error.categoryNotUpdatable }
        let params = SharedDataUpdateRequest(category: category.rawValue, data: data)
        try await httpClient.sendRequest(to: .update, parameters: params)
    }
    
    enum Error: Swift.Error {
        case categoryNotQueryable
        case categoryNotUpdatable
    }
    
    // MARK: - Types

    struct SharedDataQueryResponse: Decodable {
        let items: [SharedDataResponseEntry]
    }

    struct SharedDataResponseEntry: Decodable {
        let from: UUID
        let data: String
        let key: String?
    }

    struct SharedDataUpdateRequest: Encodable {
        let category: String
        let data: String
    }
}
