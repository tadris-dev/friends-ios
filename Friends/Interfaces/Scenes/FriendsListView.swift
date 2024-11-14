import SwiftUI
import CoreLocation

struct FriendsListView: View {
    
    @EnvironmentObject private var appState: FriendsAppState
    @Binding private var selectedFriend: Friend?
    @State private var placeForFriend: [Friend:String] = [:]
    private let showProfileAction: () -> Void
    private let showAddFriendAction: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Text("Friends").font(.title.bold())
                Spacer()
                Button("add", systemImage: "plus", action: showAddFriendAction)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                Button(action: showProfileAction){
                    FriendImageView(friend: Friend(name: "Me", location: .init(latitude: .zero, longitude: .zero)))
                }
            }
            .padding([.top, .horizontal])
            
            List(selection: $selectedFriend) {
                ForEach(appState.friends) { friend in
                    HStack {
                        FriendImageView(friend: friend)
                        Text(friend.name)
                        Spacer()
                        Text(placeForFriend[friend] ?? "").opacity(0.6)
                    }
                    .tag(friend)
                    .animation(.bouncy, value: selectedFriend == friend)
                }
                .listStyle(.plain)
                .onChange(of: appState.friends, initial: true) {
                    for friend in appState.friends {
                        Task {
                            var place = await friend.location.place
                            // TODO: Fix
                            if let currentLocation = appState.currentLocation {
                                let distance = Geocoding.formattedDistance(from: friend.location, to: currentLocation)
                                place += " (" + distance + ")"
                            }
                            placeForFriend[friend] = place
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
        .background(.clear)
    }
    
    init(
        selectedFriend: Binding<Friend?>,
        showProfileAction: @escaping () -> Void,
        showAddFriendAction: @escaping () -> Void
    ) {
        self._selectedFriend = selectedFriend
        self.showProfileAction = showProfileAction
        self.showAddFriendAction = showAddFriendAction
    }
}
