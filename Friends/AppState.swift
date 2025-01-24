import Combine
import SwiftUI
import Foundation
import OSLog

class AppState: ObservableObject {
    
    private let matrixClient: MatrixClient
    
    let locationService: LocationService
    let sessionManagement: SessionManagement
    let friendService: FriendService
    
    @Published var status = AppStatus.initialising
    
    init() {
        locationService = LocationService()
        matrixClient = MatrixClient()
        sessionManagement = SessionManagement(matrixClient: matrixClient)
        friendService = FriendService(matrixClient: matrixClient)
        
        prepare()
    }
    
    func prepare() {
        matrixClient.$status.map { status -> AppStatus in
            return switch status {
            case .initialising: .initialising
            case .waitingForAuth: .setup
            case .loggedIn, .synchronising: .main
            case .error(let error): .error(error)
            }
        }.assign(to: &$status)
    }
    
    enum AppStatus {
        case initialising
        case setup
        case main
        case error(Error)
    }
}
