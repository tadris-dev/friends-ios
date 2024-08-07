import Combine

extension Publisher {
    
    func mapToVoid() -> some Publisher<Void, Failure> {
        map { _ in () }
    }
}
