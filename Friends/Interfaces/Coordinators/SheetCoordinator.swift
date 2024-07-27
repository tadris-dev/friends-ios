import Foundation
import SwiftUI

struct SheetCoordinator: View {
    
    @EnvironmentObject private var appState: FriendsAppState
    
    @State private var path = NavigationPath()
    
    @Binding private var selectedFriend: Friend?
    @Binding private var sheetSize: SheetSize
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                FriendsNavigationView(addAction: addAction)
                    .padding([.top, .horizontal])
                List(selection: $selectedFriend) {
                    FriendsListView(selectedFriend: $selectedFriend)
                    Section("Info") {
                        
                    }
                }
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NavigationDestination.self) { destination in
                List {
                    Text("Hello")
                    Text("World")
                }
                .listStyle(.plain)
                .background(.clear)
            }
        }
        .background(Color.clear)
    }
    
    init(selectedFriend: Binding<Friend?>, sheetSize: Binding<SheetSize>) {
        self._selectedFriend = selectedFriend
        self._sheetSize = sheetSize
    }
    
    // MARK: - Action
    
    private func adjustSheet(to sheetSize: SheetSize, andNavigateTo destination: NavigationDestination) {
        withAnimation {
            self.sheetSize = sheetSize
        } completion: {
            path.append(destination)
        }
    }
    
    private func addAction() {
        adjustSheet(to: .fullScreen, andNavigateTo: .addFriend)
    }
    
    private func selectFriendAction(friend: Friend?) {
        guard let friend else { return }
        adjustSheet(to: .medium, andNavigateTo: .friendDetail(friend))
    }
    
    // MARK: - Types
    
    enum NavigationDestination: Hashable {
        case addFriend
        case friendDetail(_ friend: Friend)
    }
    
    enum SheetSize: CaseIterable {
        case small, medium, fullScreen
        
        var height: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 300
            case .fullScreen: return .infinity
            }
        }
        
        var detent: PresentationDetent {
            switch self {
            case .small, .medium:
                return .height(height)
            case .fullScreen:
                return .fraction(0.999)
            }
        }
    }
}
