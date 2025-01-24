import SwiftUI

struct RadarSweepLineMask: View {
    
    let angle: Angle
    
    var body: some View {
        AngularGradient(
            stops: [
                .init(color: .black.opacity(0), location: 0.5),
                .init(color: .black, location: 0.999),
                .init(color: .black.opacity(0), location: 1)
            ],
            center: .center,
            angle: angle
        )
    }
}
