import Foundation
import SwiftUI
import CoreData

struct UiPosition: Hashable {
    let id: Int64
    let titleText: String
    let typeText: String
    let tradeResultText: String
    let tradeResultTextColor: Color
    let action: UiActionButton?
    let corePosition: Position
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
