import Foundation
import SwiftUI

class InitChartCommand : Command {
    func execute(_ positionsObservable: PositionsObservableObject,
                 _ chartObservable: ChartObservableObject,
                 _ positions: FetchedResults<Position>,
                 restoreState: Bool) async {
        chartObservable.setupChart(restoreState)
        await MainActor.run {
            ChartUiState.shared.currentOffset = chartObservable.next(positions)
        }
        await chartObservable.saveChartState()
        
        let currentPeriod = await MainActor.run {
            return chartObservable.currentPeriod()
        }
        
        await positionsObservable.ensureStartPosition(startPrice: NSDecimalNumber(decimal: 0), endPrice: Constants.startFunds)
        await positionsObservable.recalculateFunds(currentPeriod)
        await MainActor.run {
            positionsObservable.maybeSetEndSessionCondition(currentPeriod)
        }
    }
}
