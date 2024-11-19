import SwiftUI
import OSLog

struct DebugView: View {
    
    @ObservedObject private var testSuite = DebugTestSuite()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Tests") {
                    TestItem("Obtain Public Key", action: testSuite.obtainPublicKeyTest)
                    TestItem("Register", action: testSuite.registerTest)
                    TestItem("Login", action: testSuite.loginTest)
                    TestItem("Initiate Handshake", action: testSuite.initiateHandshakeTest)
                    TestItem("Accept Handshake", action: testSuite.acceptHandshakeTest)
                    TestItem("Add Friend Public Key", action: testSuite.addFriendPublicKeyTest)
                    TestItem("Add Friend", action: testSuite.addFriendTest)
                    TestItem("Share Data", action: testSuite.shareDataTest)
                    TestItem("Query Data", action: testSuite.queryDataTest)
                    TestItem("Decrypt Data", action: testSuite.decryptDataTest)
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

fileprivate struct TestItem: View {
    
    let name: String
    let action: () async -> Bool
    @State private var state: TestState = .run
    
    var content: some View {
        state.icon.foregroundStyle(state.color)
    }
    
    var body: some View {
        LabeledContent {
            if state == .run {
                Button(action: runTest) {
                    content
                }
            } else {
                content
            }
        } label: {
            Text(name)
        }
    }
    
    
    init(_ name: String, action: @escaping () async -> Bool) {
        self.name = name
        self.action = action
    }
    
    func runTest() {
        guard state == .run else { return }
        state = .running
        Task {
            let success = await action()
            state = success ? .success : .failure
        }
    }
    
    enum TestState {
        case run, running, success, failure
        
        var icon: Image {
            switch self {
            case .run: return Image(systemName: "play.circle")
            case .running: return Image(systemName: "clock")
            case .success: return Image(systemName: "checkmark.circle")
            case .failure: return Image(systemName: "xmark.circle")
            }
        }
        
        var color: Color {
            switch self {
            case .run: return .blue
            case .running: return .gray
            case .success: return .green
            case .failure: return .red
            }
        }
    }
}
