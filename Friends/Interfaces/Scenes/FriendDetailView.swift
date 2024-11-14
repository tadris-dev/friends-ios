import SwiftUI

struct FriendDetailView: View {
    
    @Environment(\.dismiss) private var dismissAction: DismissAction
    
    @State private var place: String?
    
    let friend: Friend
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Button("close", systemImage: "xmark.circle.fill", action: { dismissAction() })
                        .symbolRenderingMode(.hierarchical)
                        .labelStyle(.iconOnly)
                        .tint(.secondary)
                        .font(.title)
                }
                FriendImageView(friend: friend, size: .large)
                Text(friend.name).font(.headline.bold())
                FriendLocationLabel(friend: friend).foregroundStyle(.secondary)
                Spacer(minLength: 30)
                HStack(alignment: .top, spacing: 16) {
                    Group {
                        ActionCardButton(
                            key: "Request precise location",
                            systemImage: "location.fill.viewfinder"
                        )
                        ActionCardButton(
                            key: "Location accuracy",
                            systemImage: "mappin.and.ellipse"
                        )
                    }
                    .frame(maxHeight: .infinity)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private struct ActionCardButton: View {
        
        let key: LocalizedStringKey
        let systemImage: String
        
        var body: some View {
            Button(action: {}) {
                HStack(alignment: .bottom) {
                    VStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: systemImage)
                                .font(.title)
                                .foregroundStyle(.tint)
                                .frame(height: UIFont.preferredFont(forTextStyle: .title1).lineHeight)
                            Text(key)
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer()
                }
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

struct FriendLocationLabel: View {
    
    let friend: Friend
    @State private var place: String?
    
    var body: some View {
        ZStack {
            if let place {
                Text(place)
            }
        }
        .onAppear {
            fetchPlace()
        }
    }
    
    private func fetchPlace() {
        Task {
            self.place = await friend.location.place
        }
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(16)
            .background(configuration.isPressed ? AnyShapeStyle(BackgroundStyle().secondary) : AnyShapeStyle(BackgroundStyle()))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.default, value: configuration.isPressed)
    }
}

#Preview {
    FriendDetailView(friend: FriendsAppState.previewInstance.friends.first!)
}
