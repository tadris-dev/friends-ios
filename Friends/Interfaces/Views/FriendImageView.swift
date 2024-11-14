import MapKit
import SwiftUI

struct FriendImageView: View {
    
    private let friend: Friend
    private let selected: Bool
    private let action: (() -> Void)?
    private let size: Size
    private var scaleSize: CGSize {
        let value: CGFloat = selected ? 7/6 : 1
        return CGSize(width: value, height: value)
    }
    
    private var image: some View {
        ZStack(alignment: .center) {
            Circle().frame(width: size.circle, height: size.circle)
                .foregroundStyle(.background)
            Circle().frame(width: size.circle - 4, height: size.circle - 4)
                .foregroundStyle(.tint)
            Text(friend.initial)
                .foregroundStyle(.white)
                .font(size.font.bold())
        }
        .scaleEffect(scaleSize, anchor: .bottom)
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
    
    init(friend: Friend, size: Size = .small, selected: Bool = false, action: (() -> Void)? = nil) {
        self.friend = friend
        self.size = size
        self.selected = selected
        self.action = action
    }
    
    enum Size {
        case small
        case large
        
        fileprivate var circle: CGFloat {
            return switch self {
            case .small: 32
            case .large: 96
            }
        }
        
        fileprivate var font: Font {
            return switch self {
            case .small: .callout
            case .large: .largeTitle
            }
        }
    }
}

#if DEBUG
#Preview {
    FriendImageView(friend: Friend.exampleFriends.first!, selected: false, action: {})
}
#endif
