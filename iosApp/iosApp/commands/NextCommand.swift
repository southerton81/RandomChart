import Foundation
import SwiftUI

class NextCommand : Command {
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject) {
        ChartUiState.shared.currentOffset = chartObservableObject.next()
        let currentPeriod = chartObservableObject.currentPeriod()
        
        Task {
            await chartObservableObject.saveChartState()
            await positionsObservableObject.recalculateFunds(currentPeriod, true)
            var isSessionEnded = await MainActor.run {
                positionsObservableObject.maybeSetEndSessionCondition(currentPeriod)
            }
            
            if (isSessionEnded) {
                await positionsObservableObject.closeAllPositions(currentPeriod, chartObservableObject.currentPeriodIndex())
                await positionsObservableObject.recalculateFunds(currentPeriod)
                await positionsObservableObject.reduceSessionPositions(currentPeriod, chartObservableObject.currentPeriodIndex())
            }
        }
    }
}
