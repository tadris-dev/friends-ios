import SwiftUI

struct LoadingModifier: ViewModifier {
    
    private var isLoading: Bool
    
    init(isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content.disabled(isLoading)
            if isLoading {
                Rectangle().foregroundStyle(.background)
                ProgressView()
            }
        }
    }
}

#Preview {
    Text("Hello, World!")
        
}
