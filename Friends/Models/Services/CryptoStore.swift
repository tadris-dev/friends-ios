import Foundation
import CryptoKit
import Security

struct CryptoStore {
    
    // MARK: - RSA Key Storage
    
    /// Stores an RSA key in the keychain.
    func storeKey(_ key: SecKey, label: String) throws {
        
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationLabel: label,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain: true,
            kSecValueRef: key,
        ] as [String: Any]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoStoreError("Unable to store item: \(status.message)")
        }
   }
    
    /// Reads an RSA key from the keychain.
    func readKey(label: String) throws -> SecKey? {
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationLabel: label,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecUseDataProtectionKeychain: true,
            kSecReturnRef: true,
        ] as [String: Any]
        
        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess: return (item as! SecKey)
        case errSecItemNotFound: return nil
        case let status: throw CryptoStoreError("Keychain read failed: \(status.message)")
        }
    }
    
    /// Removes any existing RSA key with the given label.
    func deleteKey(label: String) throws {
        let query = [
            kSecClass: kSecClassKey,
            kSecUseDataProtectionKeychain: true,
            kSecAttrApplicationLabel: label,
        ] as [String: Any]
        switch SecItemDelete(query as CFDictionary) {
        case errSecItemNotFound, errSecSuccess: break // Ignore these.
        case let status:
            throw CryptoStoreError("Unexpected deletion error: \(status.message)")
        }
    }
    
    // MARK: - Symmetric Key Storage
    
    /// Stores a SymmetricKey in the keychain as a generic password.
    func storeKey(_ key: SymmetricKey, account: String) throws {
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrService: "Test" as CFString,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: key.rawRepresentation as CFData,
        ] as [String: Any]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoStoreError("Unable to store item: \(status.message)")
        }
    }
    
    /// Reads a SymmetricKey from the keychain as a generic password.
    func readKey(account: String) throws -> SymmetricKey? {
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrService: "Test" as CFString,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
        ] as [String: Any]
        
        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return try SymmetricKey(rawRepresentation: data)
        case errSecItemNotFound: return nil
        case let status: throw CryptoStoreError("Keychain read failed: \(status.message)")
        }
    }
    
    /// Removes any existing SymmetricKey with the given account.
    func deleteKey(account: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account,
            kSecAttrService: "Test" as CFString,
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
    
    private static func determineCFError(_ error: Unmanaged<CFError>?) -> Error {
        guard let error = error?.takeRetainedValue() else {
            return CryptoStoreError("Something went wrong while interfacing with a CryptoStore.")
        }
        return error
    }
}
