import Foundation
import CryptoKit

/*
class KeyStorage {
    
    init() {
        
    }
    
    static func savePublicKey(for alias: String, publicKey: SecKey) throws {
        func createSecKey(from publicKeyData: Data) -> SecKey? {
            let keyDict: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits as String: 2048 // Adjust depending on your key size
            ]
            return SecKeyCreateWithData(publicKeyData as CFData, keyDict as CFDictionary, nil)
        }
    }
    
    static func optainPrivateKey(for alias: String) throws {
        
        let tag = "de.tadris.friends.keys.\(alias)".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw <# an error #> }
        let key = item as! SecKey
    }
    
    static func createKeys(for alias: String) throws {
        let tag = "de.tadris.friends.keys.\(alias)".data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag
            ]
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        let publicKey = SecKeyCopyPublicKey(privateKey)
    }
}
*/
