import Combine
import SwiftUI
import Foundation
import OSLog

@MainActor
class FriendsAppState: ObservableObject {
    
    private let locationService: LocationService
    private let httpClient: HTTPClient
    private let sessionManagement: SessionManagement
    private let sharedDataService: SharedDataService
    private let handshakeService: HandshakeService
    private let keyUpdateService: KeyUpdateService
    private let cryptoService: CryptoService
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var profile = Friend(name: "You", location: .init(latitude: 0, longitude: 0))
    @Published var friends: [Friend] = []
    
    var currentLocation: Location? { locationService.currentLocation }
    
    init(friends: [Friend]) {
        self.friends = friends
        let userID = if let uuidString = UserDefaults.standard.string(forKey: "userID"), let uuid = UUID(uuidString: uuidString) {
            uuid
        } else {
            UUID()
        }
        self.userID = userID
        self.locationService = LocationService()
        self.httpClient = HTTPClient()
        self.sessionManagement = SessionManagement(httpClient: httpClient)
        self.sharedDataService = SharedDataService(httpClient: httpClient)
        self.handshakeService = HandshakeService(httpClient: httpClient, sharedDataService: sharedDataService)
        self.keyUpdateService = KeyUpdateService(httpClient: httpClient)
        self.cryptoService = CryptoService(uuid: userID)
        
        Task {
            do {
                try await locationService.requestAuthorization()
            } catch {
                // TODO: Show error in user interface
            }
        }
    }
    
    #if DEBUG
    
    static let previewInstance = FriendsAppState(friends: Friend.exampleFriends)
    
    #endif
    
    // TESTS
    
    @Published var alias: String = "user"
    @Published var userID: UUID { didSet { UserDefaults.standard.set(userID.uuidString, forKey: "userID") } }
    @Published var publicKey: String = "nil"
    
    @Published var friendUUIDString: String = "nil"
    @Published var friendPublicKey: String = "nil"
    @Published var encryptedSessionKey: String = "nil"
    
    @Published var dataToSend: String = "nil"
    @Published var receivedData: String = "nil"
    @Published var decryptedData: String = "nil"
    @Published var sessionKey: String = "nil"
    
    private let logger = Logger(category: "Tests")
    
    func obtainPublicKeyTest() async -> Bool {
        do {
            let publicKey = try await cryptoService.obtainUserPublicKey().base64EncodedString()
            logger.info("OBTAIN PUBLIC KEY - Success, got public key: \(publicKey)")
            self.publicKey = publicKey
            return true
        } catch {
            logger.error("OBTAIN PUBLIC KEY - Failed to obtain public key: \(error)")
            return false
        }
    }
    
    func registerTest() async -> Bool {
        do {
            let publicKey = try await cryptoService.obtainUserPublicKey()
            let uuid = try await sessionManagement.register(with: alias, publicKey: publicKey)
            try await cryptoService.migrate(to: uuid)
            logger.info("REGISTER - Success, got assigned user ID: \(uuid)")
            userID = uuid
            return true
        } catch {
            logger.error("REGISTER - Failed to register: \(error)")
            return false
        }
    }
    
    func loginTest() async -> Bool {
        do {
            let uuid = try await sessionManagement.login(with: alias)
            logger.info("LOGIN - Successfully loggin in")
            userID = uuid
            return true
        } catch {
            logger.error("LOGIN - Failed to log in: \(error)")
            return false
        }
    }
    
    func initiateHandshakeTest() async -> Bool {
        do {
            guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
            try await handshakeService.initiateHandshake(with: friendUUID)
            logger.info("INITIATE HANDSHAKE - Success")
            return true
        } catch {
            logger.error("INITIATE HANDSHAKE - Failed: \(error)")
            return false
        }
    }
    
    func acceptHandshakeTest() async -> Bool {
        do {
            friendUUIDString = try await handshakeService.acceptHandshake().uuidString
            logger.info("ACCEPT HANDSHAKE - Success")
            return true
        } catch {
            logger.error("ACCEPT HANDSHAKE - Failed: \(error)")
            return false
        }
    }
    
    func addFriendPublicKeyTest() async -> Bool {
        do {
            guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
            guard let keyData = Data(base64Encoded: friendPublicKey) else { throw "Invalid Friend Public Key Data" }
            try await cryptoService.storeFriendPublicKey(keyData, for: friendUUID)
            logger.info("ADD FRIEND PUBLIC KEY - Success")
            return true
        } catch {
            logger.error("ADD FRIEND PUBLIC KEY - Failed: \(error)")
            return false
        }
    }
    
    func addFriendTest() async -> Bool {
        do {
            guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
            let key = try await cryptoService.encryptSessionKey(for: friendUUID)
            let entry = KeyUpdateService.UpdateKeysEntry(to: friendUUID, key: key.base64EncodedString())
            try await keyUpdateService.updateKeys([entry])
            logger.info("ADD FRIEND - Success")
            return true
        } catch {
            logger.error("ADD FRIEND - Failed: \(error)")
            return false
        }
    }
    
    func shareDataTest() async -> Bool {
        do {
            guard let data = dataToSend.data(using: .utf8) else { throw "Failed To Encode String" }
            let encryptedData = try await cryptoService.encrypt(data)
            try await sharedDataService.update(category: .location, data: encryptedData)
            logger.info("SHARE DATA - Success")
            return true
        } catch {
            logger.error("SHARE DATA - Failed: \(error)")
            return false
        }
    }
    
    func queryDataTest() async -> Bool {
        do {
            let response = try await sharedDataService.query(category: .location)
            guard let item = response.items.first else { throw "Data Missing" }
            guard let key = item.key else { throw "Session Key Missing" }
            friendUUIDString = item.from.uuidString
            encryptedSessionKey = key
            receivedData = item.data
            logger.info("QUERY DATA - Success")
            return true
        } catch {
            logger.error("QUERY DATA - Failed: \(error)")
            return false
        }
    }
    
    func decryptDataTest() async -> Bool {
        do {
            guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
            guard let encryptedData = Data(base64Encoded: receivedData) else { throw "Invalid Received Data" }
            guard let encryptedSessionKeyData = Data(base64Encoded: encryptedSessionKey) else { throw "Invalid Encrypted Session Key" }
            let decryptedData = try await cryptoService.decrypt(encryptedData, from: friendUUID, using: encryptedSessionKeyData)
            guard let encodedDecryptedData = String(data: decryptedData, encoding: .utf8) else { throw "Unable To Encode Data" }
            self.decryptedData = encodedDecryptedData
            logger.info("DECRYPT DATA - Success")
            return true
        } catch {
            logger.error("DECRYPT DATA - Failed: \(error)")
            return false
        }
    }
}
