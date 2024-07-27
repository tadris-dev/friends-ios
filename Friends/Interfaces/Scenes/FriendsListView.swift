import SwiftUI
import CoreLocation

struct FriendsListView: View {
    
    @EnvironmentObject private var appState: FriendsAppState
    
    @Binding private var selectedFriend: Friend?
    @State private var placeForFriend: [Friend:String] = [:]
    
    var body: some View {
        ForEach(appState.friends) { friend in
            HStack {
                FriendImageView(friend: friend)
                Text(friend.name)
                Spacer()
                Text(placeForFriend[friend] ?? "").opacity(0.6)
            }
            .tag(friend)
            .listRowBackground(Color.accentColor.opacity(selectedFriend == friend ? 0.25 : 0))
            .animation(.bouncy, value: selectedFriend == friend)
        }
        .listStyle(.plain)
        .onChange(of: appState.friends, initial: true) {
            for friend in appState.friends {
                getPlaceName(for: friend)
            }
        }
    }
    
    init(selectedFriend: Binding<Friend?>) {
        self._selectedFriend = selectedFriend
    }
    
    func getPlaceName(for friend: Friend) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        let lastLocation = CLLocationManager().location
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(friend.location.clLocation, completionHandler: { placemarks, error in
            if let error {
                print("error occured for friend \(friend.name): \(error)")
            } else {
                var place = placemarks?.first?.locality ?? ""
                if let lastLocation {
                    let distance = formatter.string(for: lastLocation.distance(from: friend.location.clLocation) / 1000) ?? ""
                    place += " (" + distance + " km)"
                }
                placeForFriend[friend] = place
                print("found location for friend \(friend.name): \(place)")
            }
        })
    }
}

#if DEBUG
#Preview {
    FriendsListView(selectedFriend: .variable(nil))
        .environmentObject(FriendsAppState.previewInstance)
}
#endif
