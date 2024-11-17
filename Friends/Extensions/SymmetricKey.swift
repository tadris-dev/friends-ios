import CryptoKit
import Foundation

extension SymmetricKey {
    
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        self.init(data: data)
    }
    
    var rawRepresentation: Data {
        return dataRepresentation
    }
}

extension SymmetricKey: @retroactive CustomStringConvertible {
    
    public var description: String {
        rawRepresentation.withUnsafeBytes { bytes in
            "Raw representation contains \(bytes.count) bytes."
        }
    }
}
