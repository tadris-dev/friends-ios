import SwiftUI

struct DebugTestView: View {
    
    private let name: String
    private let action: () async throws -> Void
    @State private var state: TestState = .run
    
    var content: some View {
        state.icon.foregroundStyle(state.color)
    }
    
    var body: some View {
        VStack {
            LabeledContent {
                if case .run = state {
                    Button(action: runTest) {
                        content
                    }
                } else {
                    content
                }
            } label: {
                Text(name)
            }
            if let message = state.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(state.color)
            }
        }
    }
    
    
    init(_ name: String, action: @escaping () async throws -> Void) {
        self.name = name
        self.action = action
    }
    
    func runTest() {
        guard case .run = state else { return }
        state = .running
        Task {
            do {
                try await action()
                state = .success
            } catch {
                if let error = error as? String {
                    state = .failure(error)
                } else {
                    state = .failure((error as NSError).debugDescription)
                }
            }
        }
    }
    
    private enum TestState {
        case run, running, success, failure(String)
        
        var icon: Image {
            switch self {
            case .run: return Image(systemName: "play.circle")
            case .running: return Image(systemName: "clock")
            case .success: return Image(systemName: "checkmark.circle")
            case .failure: return Image(systemName: "xmark.circle")
            }
        }
        
        var color: Color {
            switch self {
            case .run: return .blue
            case .running: return .gray
            case .success: return .green
            case .failure: return .red
            }
        }
        
        var errorMessage: String? {
            switch self {
            case .failure(let message): return message
            default: return nil
            }
        }
    }
}
