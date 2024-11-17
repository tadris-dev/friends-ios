import Foundation
import CryptoKit

class CryptoService {
    
    private(set) var uuid: UUID
    private let cryptoStore: CryptoStore
    
    init(uuid: UUID) {
        self.uuid = uuid
        self.cryptoStore = CryptoStore()
    }
    
    /// Migrates the private key of the user to a new uuid
    /// - Note: This function is only intended to be used after user registration to move the users keys from a random uuid to the server
    /// assigned uuid.
    func migrate(to uuid: UUID) async throws {
        let oldLabel = privateKeyLabel
        self.uuid = uuid
        let label = privateKeyLabel
        guard let oldPrivateKey = try cryptoStore.readKey(label: oldLabel) else { throw CryptoServiceError.privateKeyNotFound }
        try cryptoStore.storeKey(oldPrivateKey, label: label)
        try cryptoStore.deleteKey(label: oldLabel)
    }
    
    func obtainUserPublicKey() async throws -> Data {
        let task = Task {
            let privateKey = try obtainPrivateKey()
            guard let publicKey = SecKeyCopyPublicKey(privateKey) else { throw CryptoServiceError.publicKeyNotFound }
            return try Self.data(from: publicKey)
        }
        return try await task.value
    }
    
    func storeFriendPublicKey(_ keyData: Data, for friendUUID: UUID) async throws {
        let task = Task {
            
            // delete before? otherwise this will fail
            
            let label = publicKeyLabel(for: friendUUID)
            let attributes = [
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeySizeInBits: 2048,
            ] as CFDictionary
            let publicKey = try Self.secKey(from: keyData, attributes: attributes)
            try cryptoStore.storeKey(publicKey, label: label)
        }
        return try await task.value
    }
    
    /// Encrypts the users session key for the specified friend
    func encryptSessionKey(for friendUUID: UUID) async throws -> Data {
        let task = Task {
            guard let publicKey = try obtainFriendPublicKey(for: friendUUID) else { throw CryptoServiceError.publicKeyNotFound }
            let sessionKey = try obtainSessionKey()
            var error: Unmanaged<CFError>?
            let sessionKeyData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, sessionKey.rawRepresentation as CFData, &error)
            guard let sessionKeyData else { throw Self.determineCFError(error) }
            return sessionKeyData as Data
        }
        return try await task.value
    }
    
    /// Encrypts data using the users session key
    func encrypt(_ data: Data) async throws -> Data {
        let task = Task {
            let sessionKey = try obtainSessionKey()
            let encrypted = try AES.GCM.seal(data, using: sessionKey)
            guard let combinedEncryptedData = encrypted.combined else { throw CryptoServiceError.encryptedDataCombinationFailed }
            return combinedEncryptedData
        }
        return try await task.value
    }
    
    /// Decrypts the provided session key and using that the provided data
    func decrypt(_ data: Data, from friendUUID: UUID, using encryptedSessionKeyData: Data) async throws -> Data {
        let task = Task {
            let decryptedSessionKey = try decryptSessionKey(encryptedSessionKeyData, friendUUID: friendUUID)
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: decryptedSessionKey)
        }
        return try await task.value
    }
    
    // MARK: - Private
    
    private func obtainPrivateKey() throws -> SecKey {
        let label = privateKeyLabel
        if let key = try cryptoStore.readKey(label: label) {
            return key
        } else {
            let key = try Self.createRandomRSAKey()
            try cryptoStore.storeKey(key, label: label)
            return key
        }
    }
    
    private func obtainFriendPublicKey(for uuid: UUID) throws -> SecKey? {
        let label = publicKeyLabel(for: uuid)
        return try cryptoStore.readKey(label: label)
    }
    
    private func obtainSessionKey() throws -> SymmetricKey {
        let label = sessionKeyLabel
        if let key = try cryptoStore.readKey(account: label) {
            return key
        } else {
            let key = try Self.createRandomAESKey()
            try cryptoStore.storeKey(key, account: label)
            return key
        }
    }
    
    /// Decrypts an encrypted session key created for the user
    private func decryptSessionKey(_ keyData: Data, friendUUID: UUID) throws -> SymmetricKey {
        let privateKey = try obtainPrivateKey()
        var error: Unmanaged<CFError>?
        let sessionKeyData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionPKCS1, keyData as CFData, &error)
        guard let sessionKeyData else { throw Self.determineCFError(error) }
        return try SymmetricKey(rawRepresentation: sessionKeyData as Data)
    }
    
    /// Creates a random RSA private key
    private static func createRandomRSAKey() throws -> SecKey {
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
        ] as CFDictionary
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else { throw Self.determineCFError(error) }
        return privateKey
    }
    
    /// Creates a random symmetric AES key
    private static func createRandomAESKey() throws -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
    
    // MARK: Key Conversion
    
    private static func data(from secKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let cfData = SecKeyCopyExternalRepresentation(secKey, &error) else { throw determineCFError(error)  }
        return cfData as Data
    }
    
    private static func secKey(from data: Data, attributes: CFDictionary) throws -> SecKey {
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(data as CFData, attributes, &error) else { throw determineCFError(error) }
        return secKey
    }
    
    // MARK: Key Tags
    
    private let baseLabel: String = "de.tadris.friends.key"
    private var privateKeyLabel: String { baseLabel + ".private." + uuid.uuidString }
    private func publicKeyLabel(for uuid: UUID) -> String { baseLabel + ".public." + uuid.uuidString }
    private var sessionKeyLabel: String { baseLabel + ".session." + uuid.uuidString }
    
    // MARK: Error
    
    private static func determineCFError(_ error: Unmanaged<CFError>?) -> Error {
        guard let error = error?.takeRetainedValue() else { return CryptoServiceError.unknown }
        return error
    }
    
    enum CryptoServiceError: Swift.Error {
        case unknown
        case encryptedDataCombinationFailed
        case publicKeyNotFound
        case privateKeyNotFound
    }
}
