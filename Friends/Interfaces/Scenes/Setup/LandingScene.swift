import SwiftUI
import RswiftResources

struct LandingScene: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var startAngle: Angle { stackVertically ? .degrees(-60) : .degrees(-180) }
    private var endAngle: Angle { stackVertically ? .degrees(-5) : .degrees(-95) }
    
    @State private var angle: Angle = .degrees(0)
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 25
    
    private var stackVertically: Bool { verticalSizeClass == .regular }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: stackVertically ? .top : .leading) {
                ZStack {
                    RadarView(angle: angle)
                        .foregroundStyle(.linearGradient(
                            colors: [
                                Color(R.color.sweepLineGradientStart),
                                Color(R.color.sweepLineGradientEnd),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .scaleEffect(1.2)
                        .ignoresSafeArea()
                        .frame(
                            width: stackVertically ? nil : proxy.size.width * 0.75, // 0.75,
                            height: stackVertically ? proxy.size.height * 0.85 : nil // 0.85
                        )
                        .accessibilityLabel("shimmering radar view with moving sweep line")
                        // .offset(
                        //     x: stackVertically ? 0 : -proxy.size.width * 0.25,
                        //     y: stackVertically ? -proxy.size.height * 0.15 : 0
                        // )
                }
                // .frame(width: proxy.size.width, height: proxy.size.height)
                
                if stackVertically {
                    VStack {
                        content(for: proxy)
                    }
                } else {
                    HStack {
                        content(for: proxy)
                    }
                }
            }
        }
        .onChange(of: stackVertically, initial: true) { _, _ in
            angle = startAngle
            withAnimation(.smooth(duration: 1.5)) {
                angle = endAngle - .degrees(15)
                opacity = 1
                offset = 0
            } completion: {
                withAnimation(.linear(duration: 60)) {
                    angle = endAngle
                }
            }
        }
    }
    
    @ViewBuilder
    private func content(for proxy: GeometryProxy) -> some View {
        Spacer()
        VStack {
            Spacer()
            VStack {
                Text("Welcome to")
                    .font(.largeTitle)
                    
                Text("Friends")
                    .font(.scaled(size: 42, relativeTo: .largeTitle))
                    .foregroundStyle(.tint)
            }
            .fontWeight(.bold)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button {
                    withAnimation(.smooth(duration: 0.125)) {
                        opacity = 0
                    }
                    withAnimation(.smooth) {
                        angle = .degrees(360)
                    }
                } label: {
                    Text("Get Started")
                }
                .buttonStyle(.callToAction)
                
                Button { } label: {
                    Text("I already have an account")
                }
                .buttonStyle(.plain)
                .font(.headline)
                .fontWeight(.bold)
                .opacity(0.6)
            }
            .padding(.horizontal)
        }
        .multilineTextAlignment(.center)
        .frame(
            width: stackVertically ? nil : proxy.size.width * 0.6,
            height: stackVertically ? proxy.size.height * 0.6 : nil
        )
        .offset(y: offset)
        .opacity(opacity)
    }
}

#Preview {
    LandingScene()
}
