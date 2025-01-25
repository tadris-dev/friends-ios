import SwiftUI
import UIKit

extension Font {
    
    static func scaled(name: String? = nil, size: CGFloat, relativeTo fontStyle: TextStyle) -> Font {
        let name = name ?? UIFont.systemFont(ofSize: size).familyName
        return .custom(name, size: size, relativeTo: fontStyle)
    }
        
}
