import Combine

extension Publisher {
    
    func eraseError() -> some Publisher<Output, Error> {
        mapError { $0 }
    }
    
    func mapToVoid() -> some Publisher<Void, Failure> {
        map { _ in () }
    }
}
