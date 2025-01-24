import SwiftUI

extension View {
    
    func showLoading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}
