import Combine
import Foundation

class HTTPClient {
    
    func request<Paramaters: Encodable, Response: Decodable>(
        from endpoint: Endpoint,
        method: RequestMethod,
        parameters: Paramaters
    ) throws -> some Publisher<Response, HTTPClient.Error> {
        guard let url = endpoint.url else { throw Error.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(parameters)
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { element in
                if let httpResponse = element.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    throw HTTPClient.Error.operationFailed(errorCode: httpResponse.statusCode)
                }
                do {
                    return try JSONDecoder().decode(Response.self, from: element.data)
                } catch {
                    throw HTTPClient.Error.decodingError
                }
            }
            .mapError { $0 as? HTTPClient.Error ?? Error.dataTaskError(error: $0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Types
    
    enum Endpoint {
        case user
        
        var url: URL? {
            let fullPath = Globals.backendUrlPath + "/" + path
            return URL(string: fullPath)
        }
        
        private var path: String {
            switch self {
            case .user:
                return "user"
            }
        }
    }
    
    enum Error: Swift.Error, LocalizedError {
        case invalidURL
        case encodingError
        case decodingError
        case operationFailed(errorCode: Int)
        case dataTaskError(error: Swift.Error)
        
        // TODO: Add Localization
        var errorDescription: String? {
            return "API request failed."
        }
        
        var failureReason: String? {
            switch self {
            case .invalidURL:
                return "The provided URL was invalid."
            case .encodingError:
                return "The request could not be encoded."
            case .decodingError:
                return "The response could not be decoded."
            case .operationFailed(let errorCode):
                return "The http request returned error code \(errorCode)"
            case .dataTaskError(let error):
                return "The data task failed with error: \(error)"
            }
        }
    }
    
    enum RequestMethod: String {
        case get = "GET"
        case post = "POST"
    }
}
