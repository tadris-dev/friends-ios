import SwiftUI

struct RadarView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var angle: Angle
    private var puckSize: CGFloat
    
    var body: some View {
        ZStack {
            sweepLine
            radiusLines
            locationPuck
        }
    }
    
    // MARK: Location Puck
    
    private var locationPuck: some View {
        LocationPuck()
            .frame(width: puckSize, height: puckSize)
            .foregroundStyle(.white)
    }
    
    // MARK: Radius Lines
    
    private var radiusLines: some View {
        Rectangle()
            .mask { RadarRadiusLinesMask() }
            .mask { additionalRadiusLinesMask }
            .blendMode(colorScheme == .light ? .colorBurn : .colorDodge)
    }
    
    @ViewBuilder private var additionalRadiusLinesMask: some View {
        if colorScheme == .light {
            sweepLineMask
        } else {
            Color.black
        }
    }
    
    // MARK: Sweep Line
    
    private var sweepLine: some View {
        Rectangle().mask { sweepLineMask }
    }
    
    // MARK: General
    
    private var sweepLineMask: some View {
        RadarSweepLineMask(angle: angle)
    }
    
    // MARK: Init
    
    init(angle: Angle = .degrees(-15), puckSize: CGFloat = 42) {
        self.angle = angle
        self.puckSize = puckSize
    }
}
