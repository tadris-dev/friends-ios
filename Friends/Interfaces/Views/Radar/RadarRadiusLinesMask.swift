import SwiftUI

struct RadarRadiusLinesMask: View {
    
    let lineWidth: CGFloat = 4
    
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                circle(with: size)
                circle(with: size * 7 / 10)
                circle(with: size * 4 / 10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    func circle(with size: CGFloat) -> some View {
        Circle()
            .stroke(lineWidth: lineWidth)
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
    }
}
