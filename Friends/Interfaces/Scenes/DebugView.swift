import SwiftUI
import OSLog

struct DebugView: View {
    
    @ObservedObject private var testSuite = DebugTestSuite()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Tests") {
                    DebugTestView("Obtain Public Key", action: testSuite.obtainPublicKeyTest)
                    DebugTestView("Register", action: testSuite.registerTest)
                    DebugTestView("Login", action: testSuite.loginTest)
                    DebugTestView("Initiate Handshake", action: testSuite.initiateHandshakeTest)
                    DebugTestView("Accept Handshake", action: testSuite.acceptHandshakeTest)
                    DebugTestView("Add Friend Public Key", action: testSuite.addFriendPublicKeyTest)
                    DebugTestView("Add Friend", action: testSuite.addFriendTest)
                    DebugTestView("Share Data", action: testSuite.shareDataTest)
                    DebugTestView("Query Data", action: testSuite.queryDataTest)
                    DebugTestView("Decrypt Data", action: testSuite.decryptDataTest)
                }
                Section("User Data") {
                    LabeledTextField("Alias", value: $testSuite.alias)
                    LabeledText("UUID", value: testSuite.userID.uuidString)
                    LabeledText("Public Key", value: testSuite.publicKey)
                }
                Section("Friend Data") {
                    LabeledTextField("UUID", value: $testSuite.friendUUIDString)
                    LabeledTextField("Public Key", value: $testSuite.friendPublicKey)
                    LabeledText("Encrypted Session Key", value: testSuite.encryptedSessionKey)
                }
                Section("Results") {
                    LabeledTextField("Data To Send", value: $testSuite.dataToSend)
                    LabeledText("Data Received", value: testSuite.receivedData)
                    LabeledText("Decrypted Data Received", value: testSuite.decryptedData)
                    LabeledText("Session Key", value: testSuite.sessionKey)
                }
            }
        }
    }
}

fileprivate class DebugTestSuite: ObservableObject {
    
    private let httpClient: HTTPClient
    private let sessionManagement: SessionManagement
    private let sharedDataService: SharedDataService
    private let handshakeService: HandshakeService
    private let keyUpdateService: KeyUpdateService
    private let cryptoService: CryptoService
    
    private static let userIDKey = "debug_userID"
    
    @Published var alias: String = "user"
    @Published var userID: UUID { didSet { UserDefaults.standard.set(userID.uuidString, forKey: Self.userIDKey) } }
    @Published var publicKey: String = "nil"
    
    @Published var friendUUIDString: String = "nil"
    @Published var friendPublicKey: String = "nil"
    @Published var encryptedSessionKey: String = "nil"
    
    @Published var dataToSend: String = "nil"
    @Published var receivedData: String = "nil"
    @Published var decryptedData: String = "nil"
    @Published var sessionKey: String = "nil"
    
    private let logger = Logger(category: "Tests")
    
    init() {
        let userID = if let uuidString = UserDefaults.standard.string(forKey: Self.userIDKey), let uuid = UUID(uuidString: uuidString) {
            uuid
        } else {
            UUID()
        }
        self.userID = userID
        self.httpClient = HTTPClient()
        self.sessionManagement = SessionManagement(httpClient: httpClient)
        self.sharedDataService = SharedDataService(httpClient: httpClient)
        self.handshakeService = HandshakeService(httpClient: httpClient, sharedDataService: sharedDataService)
        self.keyUpdateService = KeyUpdateService(httpClient: httpClient)
        self.cryptoService = CryptoService(uuid: userID)
    }
    
    func obtainPublicKeyTest() async throws {
        let publicKey = try await cryptoService.obtainUserPublicKey().base64EncodedString()
        self.publicKey = publicKey
    }
    
    func registerTest() async throws {
        let publicKey = try await cryptoService.obtainUserPublicKey()
        let uuid = try await sessionManagement.register(with: alias, publicKey: publicKey)
        try await cryptoService.migrate(to: uuid)
        userID = uuid
    }
    
    func loginTest() async throws {
        let uuid = try await sessionManagement.login(with: alias)
        userID = uuid
    }
    
    func initiateHandshakeTest() async throws {
        guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
        try await handshakeService.initiateHandshake(with: friendUUID)
    }
    
    func acceptHandshakeTest() async throws {
        friendUUIDString = try await handshakeService.acceptHandshake().uuidString
    }
    
    func addFriendPublicKeyTest() async throws {
        guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
        guard let keyData = Data(base64Encoded: friendPublicKey) else { throw "Invalid Friend Public Key Data" }
        try await cryptoService.storeFriendPublicKey(keyData, for: friendUUID)
    }
    
    func addFriendTest() async throws {
        guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
        let key = try await cryptoService.encryptSessionKey(for: friendUUID)
        let entry = KeyUpdateService.UpdateKeysEntry(to: friendUUID, key: key.base64EncodedString())
        try await keyUpdateService.updateKeys([entry])
    }
    
    func shareDataTest() async throws {
        guard let data = dataToSend.data(using: .utf8) else { throw "Failed To Encode String" }
        let encryptedData = try await cryptoService.encrypt(data)
        try await sharedDataService.update(category: .location, data: encryptedData)
    }
    
    func queryDataTest() async throws {
        let response = try await sharedDataService.query(category: .location)
        guard let item = response.items.first else { throw "Data Missing" }
        guard let key = item.key else { throw "Session Key Missing" }
        friendUUIDString = item.from.uuidString
        encryptedSessionKey = key
        receivedData = item.data
    }
    
    func decryptDataTest() async throws {
        guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
        guard let encryptedData = Data(base64Encoded: receivedData) else { throw "Invalid Received Data" }
        guard let encryptedSessionKeyData = Data(base64Encoded: encryptedSessionKey) else { throw "Invalid Encrypted Session Key" }
        let decryptedData = try await cryptoService.decrypt(encryptedData, from: friendUUID, using: encryptedSessionKeyData)
        guard let encodedDecryptedData = String(data: decryptedData, encoding: .utf8) else { throw "Unable To Encode Data" }
        self.decryptedData = encodedDecryptedData
    }
}
