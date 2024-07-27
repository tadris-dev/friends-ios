import SwiftUI

struct FriendsNavigationView: View {
    
    var addAction: () -> Void
    
    var body: some View {
        HStack {
            Text("Friends").font(.title.bold())
            Spacer()
            Button("add", systemImage: "plus", action: addAction)
                .labelStyle(.iconOnly)
                .font(.title2)
        }
    }
}
