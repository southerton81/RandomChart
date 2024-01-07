import Foundation
import SwiftUI
import CoreData

struct UiPosition: Hashable, Identifiable {
    let id: NSManagedObjectID
    let startPeriod: Int32
    let endPeriod: Int32
    let titleText: String
    let typeText: String
    let positionValueText: String
    let tradeResultText: String
    let tradeResultTextColor: Color
    let action: UiActionButton?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
