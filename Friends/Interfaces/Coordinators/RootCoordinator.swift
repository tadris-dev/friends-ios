import Foundation
import SwiftUI

struct RootCoordinator: View {
    
    typealias SheetSize = SheetCoordinator.SheetSize
    
    @EnvironmentObject private var appState: FriendsAppState
    
    @State private var selectedFriend: Friend?
    @State private var sheetSize: SheetSize
    
    private let sheetDetents: Set<PresentationDetent>
    
    private var sheetDetentBinding: Binding<PresentationDetent> {
        Binding(
            get: { sheetSize.detent },
            set: { newValue in
                sheetSize = SheetSize.allCases.first { $0.detent == newValue } ?? .small
            }
        )
    }
    
    var body: some View {
        FriendsMapView(selectedFriend: $selectedFriend)
            .safeAreaPadding(.bottom, SheetSize.small.height)
            .sheet(item: $selectedFriend) { friend in
                VStack {
                    HStack {
                        Text(friend.name).font(.title.bold())
                        Spacer()
                        Button("close", systemImage: "xmark.circle.fill", action: { selectedFriend = nil })
                            .symbolRenderingMode(.hierarchical)
                            .labelStyle(.iconOnly)
                            .tint(.secondary)
                            .font(.title)
                    }
                    Spacer()
                }
                .padding([.horizontal, .top])
                .presentationDetents([.height(100), .fraction(0.999)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(100)))
                .presentationBackground(Material.regular)
                    
            }
            .sheet(isPresented: .constant(true)) {
                SheetCoordinator(selectedFriend: $selectedFriend, sheetSize: $sheetSize)
                    .presentationDetents(sheetDetents, selection: sheetDetentBinding)
                    .interactiveDismissDisabled()
                    .presentationBackgroundInteraction(.enabled(upThrough: SheetSize.medium.detent))
                    .presentationBackground(Material.regular)
            }
            
    }
    
    init() {
        self.sheetSize = .small
        self.sheetDetents = Set(SheetSize.allCases.map { $0.detent })
    }
}

#if DEBUG
#Preview {
    RootCoordinator()
        .environmentObject(FriendsAppState.previewInstance)
}
#endif
