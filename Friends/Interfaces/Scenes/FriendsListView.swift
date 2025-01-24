import SwiftUI
import CoreLocation

struct FriendsListView: View {
    
    @EnvironmentObject private var friendService: FriendService
    @EnvironmentObject private var locationService: LocationService
    
    @Binding private var selectedFriend: Friend?
    @State private var placeForFriendId: [String:String] = [:]
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
                Button(action: showProfileAction) {
                    // TODO: Replace with user image
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            
            List(selection: $selectedFriend) {
                ForEach(friendService.friends) { friend in
                    HStack {
                        FriendImageView(friend: friend)
                        Text(friend.name)
                        Spacer()
                        Text(placeForFriendId[friend.userId] ?? "").opacity(0.6)
                    }
                    .tag(friend)
                    .animation(.bouncy, value: selectedFriend == friend)
                }
                .listStyle(.plain)
                .onChange(of: friendService.friends, initial: true) {
                    for friend in friendService.friends {
                        Task {
                            guard let location = friend.location else { return }
                            var place = await location.place
                            // TODO: Fix
                            if let currentLocation = locationService.currentLocation {
                                let distance = Geocoding.formattedDistance(from: location, to: currentLocation)
                                place += " (" + distance + ")"
                            }
                            placeForFriendId[friend.userId] = place
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section("Friend Requests") {
                    ForEach(friendService.receivedFriendRequests) { request in
                        HStack {
                            Text(request.name)
                        }
                    }
                }
                
                Section("Sent Requests") {
                    ForEach(friendService.sentFriendRequests) { request in
                        HStack {
                            Text(request.name)
                        }
                    }
                }
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
