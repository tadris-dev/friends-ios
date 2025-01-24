import SwiftUI

struct LocationPuck: View {
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(.shadow(.inner(color: .black.opacity(0.25), radius: size * 0.08, x: .zero, y: size * -0.02)))
                    .shadow(color: .black.opacity(0.25), radius: size * 0.3, x: .zero, y: size / 10)
                Circle()
                    .foregroundStyle(.tint)
                    .frame(width: size * 2 / 3, height: size * 2 / 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
