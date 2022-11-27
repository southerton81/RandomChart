import Foundation
import SwiftUI

class NextCommand : Command {
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject) {
        currentOffset = chartObservableObject.next()
        let currentPeriod = chartObservableObject.currentPeriod()
        
        Task {
            await positionsObservableObject.recalculateFunds(currentPeriod, true)
            await MainActor.run {
                positionsObservableObject.checkEndSessionCondition(currentPeriod)
            }
        }
    }
}
