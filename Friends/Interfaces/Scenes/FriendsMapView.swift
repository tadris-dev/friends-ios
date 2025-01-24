import MapKit
import SwiftUI

struct FriendsMapView: View {
    
    @EnvironmentObject private var friendService: FriendService
    
    @Binding private var selectedFriend: Friend?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position, selection: $selectedFriend) {
            UserAnnotation()
            ForEach(friendService.friends) { friend in
                if let location = friend.location {
                    Annotation(coordinate: location.coordinate) {
                        FriendImageView(friend: friend, selected: selectedFriend == friend)
                            .padding(-4)
                    } label: {
                        Text(friend.name)
                    }
                    .tag(friend)
                }
            }
        }
        .mapControlVisibility(.visible)
        .mapControls {
            MapCompass()
            MapPitchToggle()
            MapUserLocationButton()
        }.onChange(of: selectedFriend) {
            position = if let selectedFriend, let location = selectedFriend.location {
                .region(location.region)
            } else {
                .automatic
            }
        }.animation(.bouncy, value: position)
    }
    
    init(selectedFriend: Binding<Friend?>) {
        self._selectedFriend = selectedFriend
    }
}

#if DEBUG
#Preview {
    FriendsMapView(selectedFriend: .variable(nil))
}
#endif
