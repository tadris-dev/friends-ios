import MapKit
import SwiftUI

struct FriendsMapView: View {
    
    @EnvironmentObject private var appState: FriendsAppState
    
    @Binding private var selectedFriend: Friend?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position, selection: $selectedFriend) {
            UserAnnotation()
            ForEach(appState.friends) { friend in
                Annotation(coordinate: friend.location.coordinate) {
                    FriendImageView(friend: friend, selected: selectedFriend == friend)
                        .padding(-4)
                } label: {
                    Text(friend.name)
                }
                .tag(friend)
            }
        }
        .mapControlVisibility(.visible)
        .mapControls {
            MapCompass()
            MapPitchToggle()
            MapUserLocationButton()
        }.onChange(of: selectedFriend) {
            position = if let selectedFriend {
                .region(selectedFriend.location.region)
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
