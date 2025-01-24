import Combine
import MatrixRustSDK
import OSLog

// TODO: Code session verification (client.encryption()...)
class MatrixClient: ObservableObject, ClientSessionDelegate {
    
    private static let dataPath = URL.applicationSupportDirectory.path(percentEncoded: false)
    private static let cachePath = URL.cachesDirectory.path(percentEncoded: false)
    private static let keychainSessionAccount = "sessionData"
    private static let keychainSessionService = "de.tadris.friends.matrix"
    // TODO: use friends default server
    private static let defaultServer = "matrix.org"
    
    private let logger = Logger(category: "MatrixClient")
    
    private var client: Client?
    private let cryptoStore: CryptoStore
    private(set) var syncServiceHandler: SyncServiceHandler
    private(set) var roomListServiceHandler: RoomListServiceHandler
    private(set) var verificationStateHandler: VerificationStateHandler
    
    @Published private(set) var status: MatrixClientStatus = .initialising
    @Published private(set) var sessionDeviceId: String?
    @Published private(set) var homeserver: String?
    
    // MARK: Initialisation
    
    init() {
        logger.info("Initialising")
        cryptoStore = CryptoStore()
        syncServiceHandler = SyncServiceHandler()
        roomListServiceHandler = RoomListServiceHandler()
        verificationStateHandler = VerificationStateHandler()
#if DEBUG
        // potential filter: "matrix_sdk::sliding_sync=trace,matrix_sdk_base::sliding_sync=trace",
        setupTracing(config: .init(filter: "", writeToStdoutOrSystem: true, writeToFiles: nil))
#endif
        Task {
            do {
                if let session = try getSession() {
                    logger.info("Restoring previous session")
                    try await restoreClient(for: session)
                } else {
                    logger.info("No previous session found, initialising with default server")
                    try await configureClient(for: Self.defaultServer)
                }
            } catch {
                await MainActor.run { status = .error(error) }
            }
        }
    }
    
    func sendInvite(to userId: String) async throws {
        guard let client, status.isLoggedIn else { throw MatrixClientError.notLoggedIn }
        //let roomIdMaybe = try await client.createRoom(request: .init(name: nil, topic: nil, isEncrypted: true, isDirect: true, visibility: .private, preset: .trustedPrivateChat, invite: [], avatar: nil, powerLevelContentOverride: nil, joinRuleOverride: .private, canonicalAlias: nil))
        let request = CreateRoomParameters(
            name: nil,
            isEncrypted: true,
            isDirect: true,
            visibility: .private,
            preset: .trustedPrivateChat,
            invite: [userId],
            joinRuleOverride: .private
        )
        _ = try await client.createRoom(request: request)
    }
    
    private func setupSync() async throws {
        guard let client, status.isLoggedIn else { return }
        // TODO: Check if we need UtdHook
        let syncService = try await client.syncService().finish()
        await syncServiceHandler.setup(syncService: syncService)
        try await roomListServiceHandler.setup(roomListService: syncService.roomListService())
        verificationStateHandler.setup(encryption: client.encryption())
        await MainActor.run { status = .synchronising }
    }
    
    private func resetSync() async throws {
        try await syncServiceHandler.reset()
        roomListServiceHandler.reset()
        verificationStateHandler.reset()
        await MainActor.run { status = .waitingForAuth }
    }
    
    // MARK: Session Management
    
    func login(username: String, password: String) async throws {
        logger.info("Performing login")
        guard let client, status.isInitialised else {
            logger.error("Aborting login as client is not initialised")
            throw MatrixClientError.clientNotInitialised
        }
        guard status == .waitingForAuth else {
            logger.error("Aborting login as client is not waiting for authorisation")
            throw MatrixClientError.alreadyLoggedIn
        }
        try await client.login(username: username, password: password, initialDeviceName: nil, deviceId: nil)
        let session = try client.session()
        await MainActor.run {
            status = .loggedIn
            sessionDeviceId = session.deviceId
        }
        try saveSession(session)
        try await setupSync()
    }
    
    func logout() async throws {
        logger.info("Performing logout")
        guard let client, status.isLoggedIn else { throw MatrixClientError.notLoggedIn }
        do {
            // TODO: present returned url if oidc auth was used
            _ = try await client.logout()
            // remove session from keychain to not restore on next launch
            try deleteSession()
            // remove data generated during session to enable new login
            if FileManager.default.fileExists(atPath: Self.dataPath) {
                try FileManager.default.removeItem(atPath: Self.dataPath)
            }
            if FileManager.default.fileExists(atPath: Self.cachePath) {
                try FileManager.default.removeItem(atPath: Self.cachePath)
            }
            await MainActor.run { sessionDeviceId = nil }
            try await resetSync()
            try await reconfigureClient(for: Self.defaultServer)
        } catch {
            self.status = .error(error)
        }
    }
    
    // MARK: Session Storage
    
    private func saveSession(_ session: Session) throws {
        let sessionData = try JSONEncoder().encode(session)
        try CryptoStore().storeData(sessionData, account: Self.keychainSessionAccount, service: Self.keychainSessionService)
    }
    
    private func getSession() throws -> Session? {
        guard let sessionData = try CryptoStore().readData(account: Self.keychainSessionAccount, service: Self.keychainSessionService)
        else { return nil }
        return try JSONDecoder().decode(Session.self, from: sessionData)
    }
    
    private func deleteSession() throws {
        try CryptoStore().deleteData(account: Self.keychainSessionAccount, service: Self.keychainSessionService)
    }
    
    // MARK: Client Configuration
    
    private func baseClientBuilder(for server: String) -> ClientBuilder {
        ClientBuilder()
            .serverNameOrHomeserverUrl(serverNameOrUrl: server)
            .sessionPaths(dataPath: Self.dataPath, cachePath: Self.cachePath)
    }
    
    private func configureClient(for server: String) async throws {
        let client = try await baseClientBuilder(for: server).slidingSyncVersionBuilder(versionBuilder: .discoverNative).build()
        guard await client.homeserverLoginDetails().supportsPasswordLogin() else {
            logger.error("Server does not support password login")
            await MainActor.run { status = .error(MatrixClientError.passwordLoginNotSupported) }
            throw MatrixClientError.passwordLoginNotSupported
        }
        self.client = client
        await MainActor.run {
            homeserver = server
            status = .waitingForAuth
        }
    }
    
    private func restoreClient(for session: Session) async throws {
        let client = try await baseClientBuilder(for: session.homeserverUrl).setSessionDelegate(sessionDelegate: self).build()
        self.client = client
        try await client.restoreSession(session: session)
        await MainActor.run {
            homeserver = session.homeserverUrl
            status = .loggedIn
            sessionDeviceId = session.deviceId
        }
        try await setupSync()
    }
    
    func reconfigureClient(for server: String) async throws {
        logger.info("Reconfiguring for server \(server, privacy: .sensitive(mask: .hash))")
        guard status.isInitialised else {
            logger.error("Aborting reconfiguration as client is not initialised")
            throw MatrixClientError.clientNotInitialised
        }
        guard status == .waitingForAuth else {
            logger.error("Aborting reconfiguration as client is not waiting for authorisation")
            throw MatrixClientError.alreadyLoggedIn
        }
        await MainActor.run { status = .initialising }
        try await configureClient(for: server)
    }
    
    // MARK: ClientSessionDelegate
    
    func retrieveSessionFromKeychain(userId: String) throws -> Session {
        guard let session = try getSession(), session.userId == userId else { throw MatrixClientError.noSessionFound }
        return session
    }
    
    func saveSessionInKeychain(session: Session) {
        do {
            try saveSession(session)
        } catch {
            logger.error("Failed to save session in keychain: \(error)")
        }
    }
    
    // MARK: Status
    
    enum MatrixClientStatus: Equatable {
        case initialising
        case waitingForAuth
        case loggedIn
        case synchronising
        case error(Error)
        
        var isInitialised: Bool {
            return switch self {
            case .initialising, .error: false
            case .waitingForAuth, .loggedIn, .synchronising: true
            }
        }
        
        var isLoggedIn: Bool {
            return switch self {
            case .loggedIn, .synchronising: true
            case .initialising, .waitingForAuth, .error: false
            }
        }
        
        static func == (lhs: MatrixClientStatus, rhs: MatrixClientStatus) -> Bool {
            return switch (lhs, rhs) {
            case (.initialising, .initialising),
                (.waitingForAuth, .waitingForAuth),
                (.loggedIn, .loggedIn),
                (.synchronising, .synchronising),
                (.error, .error):
                true
            default:
                false
            }
        }
    }
    
    // MARK: Error
    
    enum MatrixClientError: String, Error {
        case alreadyLoggedIn
        case clientNotInitialised
        case noServerConfigured
        case notLoggedIn
        case passwordLoginNotSupported
        case noSessionFound
    }
}
