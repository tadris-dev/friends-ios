import Foundation
import MapKit
import SwiftUI

struct MainCoordinator: View {
    
    @EnvironmentObject private var appState: FriendsAppState
    
    @State private var sheetState: SheetState
    @State private var sheetSize: SheetSize
    
    private let sheetDetents: Set<PresentationDetent>
    
    private var sheetDetentBinding: Binding<PresentationDetent> {
        Binding(get: { sheetSize.detent }, set: { sheetSize = SheetSize(detent: $0) ?? .small })
    }
    private var selectedFriend: Binding<Friend?> {
        Binding(get: { sheetState.friend }, set: { sheetState = SheetState(friend: $0) ?? .main })
    }
    private var sheetStateBinding: Binding<SheetState?> {
        Binding(get: { sheetState }, set: { sheetState = $0 ?? .main })
    }
    
    var body: some View {
        FriendsMapView(selectedFriend: selectedFriend)
            .safeAreaPadding(.bottom, SheetSize.small.height)
            .sheet(item: sheetStateBinding) { state in
                Group {
                    switch state {
                    case .main:
                        FriendsListView(
                            selectedFriend: selectedFriend,
                            showProfileAction: { sheetState = .profile },
                            showAddFriendAction: { sheetState = .addFriend }
                        )
                        .presentationDetents(sheetDetents, selection: sheetDetentBinding)
                        .interactiveDismissDisabled()
                        
                    case .friendDetail(let friend):
                        FriendDetailView(friend: friend)
                            .padding([.horizontal, .top])
                            .presentationDetents(Set([SheetSize.medium, .fullScreen].map { $0.detent }))
                    default:
                        Text("Not implemented")
                            .presentationDetents(Set([SheetSize.small.detent]))
                    }
                }
                .presentationBackgroundInteraction(.enabled(upThrough: SheetSize.medium.detent))
                .presentationBackground(Material.regular)
            }
    }
    
    init() {
        self.sheetState = .main
        self.sheetSize = .medium
        self.sheetDetents = Set(SheetSize.allCases.map { $0.detent })
    }
    
    // MARK: - Types
    
    enum SheetSize: CaseIterable {
        case small, medium, fullScreen
        
        var height: CGFloat {
            switch self {
            case .small: return 60
            case .medium, .fullScreen: return 300
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
        
        init?(detent: PresentationDetent) {
            guard let value = Self.allCases.first(where: { $0.detent == detent }) else { return nil }
            self = value
        }
    }
    
    enum SheetState: Hashable, Identifiable {
        case main
        case addFriend
        case friendDetail(Friend)
        case settings
        case profile
        
        var id: Int { hashValue }
        
        var friend: Friend? {
            guard case .friendDetail(let friend) = self else { return nil }
            return friend
        }
        
        init?(friend: Friend?) {
            guard let friend else { self = .main; return }
            self = .friendDetail(friend)
        }
    }
}

#if DEBUG
#Preview {
    MainCoordinator()
        .environmentObject(FriendsAppState.previewInstance)
}
#endif
