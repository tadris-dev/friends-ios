import Foundation
import MatrixRustSDK

extension SlidingSyncVersion: Codable {
    
    private enum WrappedType: String, Codable {
        case native
        case proxy
        case none
    }
    
    private enum CodingKeys: CodingKey {
        case type
        case url
    }
    
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(WrappedType.self, forKey: CodingKeys.type) {
        case .native:
            self = .native
        case .proxy:
            let url = try container.decode(String.self, forKey: CodingKeys.url)
            self = .proxy(url: url)
        case .none:
            self = .none
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .native:
            try container.encode(WrappedType.native, forKey: CodingKeys.type)
        case .proxy(let url):
            try container.encode(WrappedType.proxy, forKey: CodingKeys.type)
            try container.encode(url, forKey: CodingKeys.url)
        case .none:
            try container.encode(WrappedType.none, forKey: CodingKeys.type)
        }
    }
}
