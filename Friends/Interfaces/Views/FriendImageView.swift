import MapKit
import SwiftUI

struct FriendImageView: View {
    
    private let friend: Friend
    private let selected: Bool
    private let action: (() -> Void)?
    
    private var size: CGFloat {
        selected ? 42 : 36
    }
    
    private var image: some View {
        ZStack(alignment: .center) {
            Circle().frame(width: 36, height: 36)
                .foregroundStyle(.background)
            Circle().frame(width: 36 - 4, height: 36 - 4)
                .foregroundStyle(.tint)
            Text(friend.initial)
                .foregroundStyle(.white)
                .font(.callout.bold())
        }
        .scaleEffect(CGSize(width: size / 36, height: size / 36), anchor: .bottom)
        .animation(.bouncy, value: selected)
    }
    
    var body: some View {
        if let action {
            Button(action: action) {
                image
            }
        } else {
            image
        }
    }
    
    init(friend: Friend, selected: Bool = false, action: (() -> Void)? = nil) {
        self.friend = friend
        self.selected = selected
        self.action = action
    }
}

#if DEBUG
#Preview {
    FriendImageView(friend: Friend.exampleFriends.first!, selected: false, action: {})
}
#endif
