import Foundation
import SwiftUI

protocol Decoration {
    func toPath() -> any View
}

struct LineDecoration : Decoration {
    public let start: CGPoint
    public let end: CGPoint
    public let color: Color
    
    func toPath() -> any View {
        return Path { path in
            path.move(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
        }.stroke(Color(UIColor.systemGreen), lineWidth: 1)
    }
}
