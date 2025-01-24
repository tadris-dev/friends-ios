import Combine
import MatrixRustSDK
import OSLog

/// Publishes the current verification state of the matrix encryption service.
class VerificationStateHandler: VerificationStateListener {
    
    private let logger = Logger(category: "VerificationStateHandler")
    private let stateSubject = CurrentValueSubject<VerificationState, Never>(.unknown)
    private var stateListenerHandle: TaskHandle?
    
    var state: VerificationState { stateSubject.value }
    var statePublisher: AnyPublisher<VerificationState, Never> { stateSubject.eraseToAnyPublisher() }
    
    // MARK: Initialisation
    
    func setup(encryption: Encryption) {
        guard state == .unknown else { return }
        stateSubject.send(encryption.verificationState())
        stateListenerHandle = encryption.verificationStateListener(listener: self)
    }
    
    func reset() {
        stateListenerHandle?.cancel()
        stateListenerHandle = nil
        stateSubject.send(.unknown)
    }
    
    // MARK: VerificationStateListener
    
    func onUpdate(status: VerificationState) {
        logger.info("Received verification state update: \(String(describing: status))")
        stateSubject.send(status)
    }
}
