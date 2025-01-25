import SwiftUI

struct CallToActionButtonStyle: ButtonStyle {
    
    @Environment(\.controlSize) var controlSize
        
    func makeBody(configuration: Configuration) -> some View {
        let backgroundStyle = configuration.isPressed ? AnyShapeStyle(.tint.secondary) : AnyShapeStyle(.tint)
        configuration.label
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .animation(.default, value: configuration.isPressed)
    }
}
