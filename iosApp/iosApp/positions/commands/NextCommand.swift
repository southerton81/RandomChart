import Foundation
import SwiftUI

class NextCommand: Command {
    typealias ParamType = Double
    
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject,
                 _ positionSize: Double) {
        if (!positionsObservableObject.calculating) {
            currentOffset = chartObservableObject.next(currentOffset)
            let currentPeriod = chartObservableObject.currentPeriod()
            
            Task {
                await chartObservableObject.saveChartState()
                await positionsObservableObject.recalculateFunds(currentPeriod, true)
                await MainActor.run {
                    positionsObservableObject.recalculatePositionSize(positionSize)
                    positionsObservableObject.checkEndSessionCondition(currentPeriod)
                }
            }
        }
    }
}
