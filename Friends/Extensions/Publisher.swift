import Combine

extension Publisher {
    
    func eraseError() -> some Publisher<Output, Error> {
        mapError { $0 }
    }
    
    func ignoreNil<T>() -> some Publisher<T, Failure> where Output == Optional<T> {
        compactMap { $0 }
    }
    
    func mapToVoid() -> some Publisher<Void, Failure> {
        map { _ in () }
    }
}
