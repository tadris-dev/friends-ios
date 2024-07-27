import Foundation
import UIKit

enum WindowHeightHelper {
    
    private static var keyWindow: UIWindow? { (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow }
    
    static func safeAreaFraction(_ fraction: CGFloat) -> CGFloat {
        guard let keyWindow else { return 0 }
        return keyWindow.frame.inset(by: keyWindow.safeAreaInsets).height * fraction
    }
}
