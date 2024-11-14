import Combine
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
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var profile = Friend(name: "You", location: .init(latitude: 0, longitude: 0))
    @Published var friends: [Friend] = []
    
    var currentLocation: Location? { locationService.currentLocation }
    
    init(friends: [Friend]) {
        self.friends = friends
        self.locationService = LocationService()
        self.httpClient = HTTPClient()
        self.sessionManagement = SessionManagement(httpClient: httpClient)
        self.sharedDataService = SharedDataService(httpClient: httpClient)
        self.handshakeService = HandshakeService(httpClient: httpClient, sharedDataService: sharedDataService)
        self.keyUpdateService = KeyUpdateService(httpClient: httpClient)
        
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
    
    // responses
    @Published var userID: UUID?
    
    // parameters
    @Published var alias: String = "user"
    @Published var friendUUIDString: String = "nil"
    @Published var sharedData: String = "nil"
    
    private let logger = Logger(category: "Tests")
    
    func registerTest() async -> Bool {
        do {
            let uuid = try await sessionManagement.register(with: alias)
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
            logger.info("LOGIN - Successfully registered")
            userID = uuid
            return true
        } catch {
            logger.error("LOGIN - Failed to register: \(error)")
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
    
    func addFriendTest() async -> Bool {
        do {
            guard let friendUUID = UUID(uuidString: friendUUIDString) else { throw "Invalid Friend UUID" }
            let key = KeyUpdateService.UpdateKeysEntry(to: friendUUID, key: "123")
            try await keyUpdateService.updateKeys([key])
            logger.info("ADD FRIEND - Success")
            return true
        } catch {
            logger.error("ADD FRIEND - Failed: \(error)")
            return false
        }
    }
    
    func shareDataTest() async -> Bool {
        do {
            try await sharedDataService.update(category: .location, data: sharedData)
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
            guard let data = response.items.first?.data else { throw "Data Missing" }
            sharedData = data
            logger.info("QUERY DATA - Success")
            return true
        } catch {
            logger.error("QUERY DATA - Failed: \(error)")
            return false
        }
    }
}
