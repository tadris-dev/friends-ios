enum SharedItemCategory: String {
    
    case handshake
    case location
    
    var isShared: Bool {
        switch self {
        case .handshake: return false
        case .location: return true
        }
    }
}
