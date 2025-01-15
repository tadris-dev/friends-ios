import Foundation
import CryptoKit
import Security

struct CryptoStore {
    
    /// Stores data in the keychain as a generic password.
    func storeData(_ data: Data, account: String, service: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account as CFString,
            kSecAttrService: service as CFString,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain: true,
            kSecAttrSynchronizable: false,
            kSecValueData: data as CFData,
        ] as [String: Any]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoStoreError("Unable to store item: \(status.message)")
        }
    }
    
    /// Reads data from the keychain as a generic password.
    func readData(account: String, service: String) throws -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account as CFString,
            kSecAttrService: service as CFString,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
        ] as [String: Any]
        
        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess: return item as? Data
        case errSecItemNotFound: return nil
        case let status: throw CryptoStoreError("Keychain read failed: \(status.message)")
        }
    }
    
    /// Removes existing data saved as a generic password.
    func deleteData(account: String, service: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account as CFString,
            kSecAttrService: service as CFString,
            kSecUseDataProtectionKeychain: true,
        ] as [String: Any]
        switch SecItemDelete(query as CFDictionary) {
        case errSecItemNotFound, errSecSuccess: break
        case let status:
            throw CryptoStoreError("Unexpected deletion error: \(status.message)")
        }
    }
    
    // MARK: Error Management
    
    struct CryptoStoreError: Error, CustomStringConvertible {
        var message: String
        
        init(_ message: String) {
            self.message = message
        }
        
        public var description: String {
            return message
        }
    }
}
