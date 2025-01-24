import Foundation
import SwiftUI

struct RootCoordinator: View {
    
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        switch appState.status {
        case .initialising:
            ProgressView().progressViewStyle(.circular)
        case .setup:
            SetupCoordinator()
        case .main:
            MainCoordinator()
        case .error(let error):
            VStack {
                Image(systemName: Constants.SystemImages.error)
                    .font(.largeTitle)
                Text("\(error.localizedDescription)")
            }
            .foregroundStyle(.red)
        }
    }
}

