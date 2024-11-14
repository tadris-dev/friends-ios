import Combine
import Foundation

class HTTPClient {
    
    typealias Publisher<Output> = AnyPublisher<Output, HTTPClient.Error>
    private typealias CombinePublisher<Output> = Combine.Publisher<Output, HTTPClient.Error>
    
    func sendRequest<Parameters: Encodable>(to endpoint: APIEndpoint, parameters: Parameters) async throws {
        let request = try urlRequest(for: endpoint, encoding: parameters)
        try await dataTask(for: request)
    }
    
    func sendRequest<Response: Decodable>(to endpoint: APIEndpoint) async throws -> Response {
        let request = try baseUrlRequest(for: endpoint)
        return try await dataTask(for: request)
    }
    
    func sendRequest<Parameters: Encodable, Response: Decodable>(to endpoint: APIEndpoint, parameters: Parameters) async throws -> Response {
        let request = try urlRequest(for: endpoint, encoding: parameters)
        return try await dataTask(for: request)
    }
    
    private func urlRequest<Parameters: Encodable>(
        for endpoint: APIEndpoint,
        encoding parameters: Parameters
    ) throws -> URLRequest {
        var request = try baseUrlRequest(for: endpoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(parameters)
        return request
    }
    
    private func baseUrlRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = endpoint.url else { throw Error.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        return request
    }
    
    // MARK: - Publishers
    
    private func dataTask<Response: Decodable>(for request: URLRequest) async throws -> Response {
        let data = try await dataTask(for: request)
        return try JSONDecoder().decode(Response.self, from: data)
    }
    
    @discardableResult
    private func dataTask(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw HTTPClient.Error.operationFailed(errorCode: httpResponse.statusCode)
        }
        return data
    }
    
    // MARK: - Types
    
    enum Error: Swift.Error, LocalizedError {
        case invalidURL
        case operationFailed(errorCode: Int)
        
        // TODO: Add Localization
        var errorDescription: String? {
            let base = "API request failed. "
            let reason = switch self {
            case .invalidURL:
                "The provided URL was invalid."
            case .operationFailed(let errorCode):
                "The http request returned error code \(errorCode)"
            }
            return base + reason
        }
    }
}
