import Foundation
import SwiftUI

class ResetCommand : Command {
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject) {
        let currentPeriod = chartObservableObject.currentPeriod()
        
        Task {
            await chartObservableObject.saveChartState()
            await positionsObservableObject.recalculateFunds(currentPeriod, true)
            await MainActor.run {
                positionsObservableObject.maybeSetEndSessionCondition(currentPeriod, reset: true)
            }
            await positionsObservableObject.closeAllPositions(currentPeriod, chartObservableObject.currentPeriodIndex())
            await positionsObservableObject.recalculateFunds(currentPeriod)
            await positionsObservableObject.reduceSessionPositions(currentPeriod, chartObservableObject.currentPeriodIndex())
        }
    }
}
