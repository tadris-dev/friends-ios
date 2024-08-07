import CryptoKit
import Foundation

enum HashingHelper {
    
    static func sha256(for string: String) -> String {
        let data = Data(string.utf8)
        var hashFunction = SHA256()
        hashFunction.update(data: data)
        let hash = hashFunction.finalize()
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}
