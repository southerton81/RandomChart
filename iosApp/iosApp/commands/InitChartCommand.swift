import Foundation

class InitChartCommand : Command {
    func execute(_ positionsObservable: PositionsObservableObject,
                 _ chartObservable: ChartObservableObject,
                 restoreState: Bool) async {
        await chartObservable.setupChart(restoreState)
        await MainActor.run {
            ChartUiState.shared.currentOffset = chartObservable.next()
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
