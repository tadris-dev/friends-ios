import Combine
import Foundation

class HTTPClient {
    
    func request(from endpoint: Endpoint, method: RequestMethod) -> Publisher<Void> {
        do {
            let request = try baseUrlRequest(for: endpoint, and: method)
            return dataTaskPublisher(for: request).mapToVoid().eraseToAnyPublisher()
        } catch {
            return errorPublisher(for: error)
        }
    }
    
    func request<Paramaters: Encodable, Response: Decodable>(
        from endpoint: Endpoint,
        method: RequestMethod,
        parameters: Paramaters
    ) -> Publisher<Response> {
        do {
            var request = try baseUrlRequest(for: endpoint, and: method)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(parameters)
            return dataTaskPublisher(for: request).eraseToAnyPublisher()
        } catch {
            return errorPublisher(for: error, failsafe: .encodingError(error))
        }
    }
    
    private func baseUrlRequest(for endpoint: Endpoint, and method: RequestMethod) throws -> URLRequest {
        guard let url = endpoint.url else { throw Error.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return request
    }
    
    // MARK: - Publishers
    
    private func dataTaskPublisher<Response: Decodable>(for request: URLRequest) -> some CombinePublisher<Response> {
        dataTaskPublisher(for: request)
            .tryMap { data in
                do {
                    return try JSONDecoder().decode(Response.self, from: data)
                } catch {
                    throw HTTPClient.Error.decodingError(error)
                }
            }
            .mapError(errorMapper)
    }
    
    private func dataTaskPublisher(for request: URLRequest) -> some CombinePublisher<Data> {
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { element in
                if let httpResponse = element.response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    throw HTTPClient.Error.operationFailed(errorCode: httpResponse.statusCode)
                }
                return element.data
            }
            .mapError(errorMapper)
    }
    
    private func errorPublisher<Response>(for error: Swift.Error) -> Publisher<Response> {
        errorPublisher(for: errorMapper(error))
    }
    
    private func errorPublisher<Response>(for error: Swift.Error, failsafe: HTTPClient.Error) -> Publisher<Response> {
        errorPublisher(for: error as? HTTPClient.Error ?? failsafe)
    }
    
    private func errorPublisher<Response>(for clientError: HTTPClient.Error) -> Publisher<Response> {
        Fail(error: clientError).eraseToAnyPublisher()
    }
    
    // MARK: - Mappers
    
    private let errorMapper: (Swift.Error) -> HTTPClient.Error = {
        $0 as? HTTPClient.Error ?? Error.externalError($0)
    }
    
    // MARK: - Types
    
    typealias Publisher<Output> = AnyPublisher<Output, HTTPClient.Error>
    private typealias CombinePublisher<Output> = Combine.Publisher<Output, HTTPClient.Error>
    
    enum Endpoint {
        
        // Session Management
        
        case user
        case session
        case logout
        
        fileprivate var url: URL? {
            let fullPath = Globals.backendUrlPath + "/" + path
            return URL(string: fullPath)
        }
        
        private var path: String {
            switch self {
            case .user:
                return "user"
            case .session:
                return "session"
            case .logout:
                return "logout"
            }
        }
    }
    
    enum Error: Swift.Error, LocalizedError {
        case invalidURL
        case encodingError(Swift.Error)
        case decodingError(Swift.Error)
        case operationFailed(errorCode: Int)
        case externalError(Swift.Error)
        
        // TODO: Add Localization
        var errorDescription: String? {
            let base = "API request failed. "
            let reason = switch self {
            case .invalidURL:
                "The provided URL was invalid."
            case .encodingError(let error):
                "The request could not be encoded: \(error)"
            case .decodingError(let error):
                "The response could not be decoded: \(error)"
            case .operationFailed(let errorCode):
                "The http request returned error code \(errorCode)"
            case .externalError(let error):
                "Some external code failed with error: \(error)"
            }
            return base + reason
        }
    }
    
    enum RequestMethod: String {
        case get = "GET"
        case post = "POST"
    }
}
