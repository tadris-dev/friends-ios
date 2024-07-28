import OSLog

extension Logger {
    
    /// Creates a logger using the specified category and assuming the current bundle identifier as the subsystem.
    init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier ?? "MissingBundleIdentifier", category: category)
    }
}
