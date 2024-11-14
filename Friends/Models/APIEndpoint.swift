import Foundation

enum APIEndpoint {
    
    /// Register a new user
    case user
    /// Create a new session
    case session
    /// Logout the current session
    case logout
    /// Send a friend request
    case handshake
    /// Update  information
    case update
    /// Query the specified message
    case query(SharedItemCategory)
    /// Upload encrypted key to decode your messages for all friends
    case keys
    
    var url: URL? {
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
        case .handshake:
            return "handshake"
        case .update:
            return "update"
        case .query(let category):
            return "query/\(category.rawValue)"
        case .keys:
            return "keys"
        }
    }
    
    var method: HTTPRequestMethod {
        switch self {
        case .user, .session, .handshake:
            return .post
        case .logout, .query:
            return .get
        case .update, .keys:
            return .put
        }
    }
}
