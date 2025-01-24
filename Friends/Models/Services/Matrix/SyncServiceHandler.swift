import Combine
import MatrixRustSDK
import OSLog

/// Manages the SyncService, restores it on error and publishes its state.
class SyncServiceHandler: SyncServiceStateObserver {
    
    private let logger = Logger(category: "SyncServiceHandler")
    private let stateSubject = CurrentValueSubject<SyncServiceState, Never>(.idle)
    private var stateListenerHandle: TaskHandle?
    
    var syncService: SyncService?
    
    var state: SyncServiceState { stateSubject.value }
    var statePublisher: AnyPublisher<SyncServiceState, Never> { stateSubject.eraseToAnyPublisher() }
    
    // MARK: Initialisation
    
    func setup(syncService: SyncService) async {
        guard state == .idle else { return }
        self.syncService = syncService
        stateListenerHandle = syncService.state(listener: self)
        await syncService.start()
    }
    
    func reset() async throws {
        try await syncService?.stop()
        syncService = nil
        stateListenerHandle?.cancel()
        stateListenerHandle = nil
        stateSubject.send(.idle)
    }
    
    // MARK: SyncServiceStateObserver
    
    func onUpdate(state: SyncServiceState) {
        logger.info("Received sync service update: \(String(describing: state))")
        switch state {
        case .running, .terminated, .idle:
            break
        case .error:
            logger.error("Trying to restart sync service.")
            Task {
                await syncService?.start()
            }
        }
        stateSubject.send(state)
    }
}
