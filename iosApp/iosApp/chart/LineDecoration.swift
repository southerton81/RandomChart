import Foundation
import SwiftUI

protocol Decoration {
    func toPath(_ path: inout Path)
}

struct LineDecoration : Decoration {
    public let start: CGPoint
    public let end: CGPoint
    
    func toPath(_ path: inout Path) {
        path.move(to: CGPoint(x: start.x, y: start.y))
        path.addLine(to: CGPoint(x: end.x, y: end.y))
    }
}

struct CircleDecoration : Decoration {
    public let start: CGPoint
    public let end: CGPoint
    public let radius: CGFloat
    
    func toPath(_ path: inout Path) {
        path.move(to: CGPoint(x: start.x, y: start.y - radius))
        path.addArc(center: CGPoint(x: start.x, y: start.y), radius: radius, startAngle: .degrees(270), endAngle: .degrees(240), clockwise: false)
    }
}
