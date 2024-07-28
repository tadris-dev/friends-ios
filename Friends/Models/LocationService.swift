import Combine
import CoreLocation
import OSLog

fileprivate let logger = Logger(category: "LocationService")

class LocationService: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    private let authorizationStatusSubject = CurrentValueSubject<AuthorizationStatus, Never>(.initializing)
    private let currentLocationSubject = CurrentValueSubject<Location?, Never>(nil)
    
    var authorizationStatus: AuthorizationStatus { authorizationStatusSubject.value }
    var currentLocation: Location? { currentLocationSubject.value }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .other
        locationManager.distanceFilter = 10
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        var iterator = authorizationStatusSubject.values.makeAsyncIterator()
        var requestWhenInUseAuthorization = true
        if authorizationStatus == .initializing {
            while let status = await iterator.next() {
                switch status {
                case .partiallyAuthorized:
                    requestWhenInUseAuthorization = false
                case .fullyAuthorized:
                    return
                case .initializing, .notDetermined:
                    continue
                default:
                    try handleAuthorizationErrorCases(for: status)
                }
            }
        }
        if requestWhenInUseAuthorization {
            await MainActor.run {
                locationManager.requestWhenInUseAuthorization()
            }
        }
        var firstPartiallyAuthorized = requestWhenInUseAuthorization
        while let status = await iterator.next() {
            switch status {
            case .partiallyAuthorized:
                guard firstPartiallyAuthorized else { throw AuthorizationError.locationAccessRestricted }
                firstPartiallyAuthorized = false
                await MainActor.run {
                    locationManager.requestAlwaysAuthorization()
                }
            case .fullyAuthorized:
                return
            case .initializing, .notDetermined:
                continue
            default:
                try handleAuthorizationErrorCases(for: status)
            }
        }
    }
    
    private func handleAuthorizationErrorCases(for status: AuthorizationStatus) throws {
        switch status {
        case .unauthorized:
            throw AuthorizationError.locationAccessDenied
        case .disabled:
            throw AuthorizationError.locationServicesDisabled
        default:
            return
        }
    }
    
    // MARK: - Location Updates
    
    private func prepareReceivingLocationUpdates() {
        
        guard authorizationStatus.canReceiveLocationUpdates else { return }
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        
        // let backgroundSession = CLBackgroundActivitySession()
        // let serviceSession = CLServiceSession(authorization: .always, fullAccuracyPurposeKey: <#T##String#>)
        
        // Task {
        //     let monitor = await CLMonitor("monitor")
        //     let coordinate = CLLocationCoordinate2D()
        //     let condition = CLMonitor.CircularGeographicCondition(center: coordinate, radius: 100)
        //     await monitor.add(condition, identifier: "current_location_change", assuming: .satisfied)
        // }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        logger.info("received location")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        logger.error("manager failed with error")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let status = AuthorizationStatus(from: manager.authorizationStatus) else {
            // TODO: Potentially handle error cases
            logger.error("failed to handle auth status update")
            return
        }
        authorizationStatusSubject.send(status)
        prepareReceivingLocationUpdates()
        logger.info("auth changed to \(status)")
    }
    
    // MARK: - Types
    
    enum AuthorizationError: Error {
        /// The user has either disabled locations services globally or for this app.
        case locationServicesDisabled
        /// When prompted the user chose to not authorize this app for location access.
        case locationAccessDenied
        /// When prompted the user chose to not give full location access to this app.
        case locationAccessRestricted
    }
    
    enum OperationError: Error {
        /// The `CoreLocation` location manager failed.
        case managerFailedWith(Error)
    }
    
    enum AuthorizationStatus: String, Hashable, CustomStringConvertible {
        /// This service is being initialised.
        case initializing
        /// The app is not yet authorized for location access.
        case notDetermined
        /// Location authorization was explicitly denied.
        case unauthorized
        /// The app has when in use location authorization, meaning updates can only be received when in foreground.
        case partiallyAuthorized
        /// The app has always location authorization; Updates can also be received from the background or after termination.
        case fullyAuthorized
        /// The user has either disabled locations services globally or for this app.
        case disabled
        
        var description: String { self.rawValue }
        
        var canReceiveLocationUpdates: Bool {
            switch self {
            case .partiallyAuthorized, .fullyAuthorized: return true
            default: return false
            }
        }
        
        init?(from clAuthorizationStatus: CLAuthorizationStatus) {
            switch clAuthorizationStatus {
            case .notDetermined: self = .notDetermined
            case .restricted: self = .unauthorized
            case .denied: self = .disabled
            case .authorizedAlways: self = .fullyAuthorized
            case .authorizedWhenInUse: self = .partiallyAuthorized
            @unknown default: return nil
            }
        }
    }
}
