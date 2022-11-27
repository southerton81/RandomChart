import Foundation


class ResetCommand : Command {
    func execute(_ positionsObservable: PositionsObservableObject,
                 _ chartObservable: ChartObservableObject) async {
        await chartObservable.setupChart()
        
        await MainActor.run {
            chartObservable.generatePeriodsRects(0)
            currentOffset = chartObservable.next()
        }
        
        let currentPeriod = await MainActor.run {
            return chartObservable.currentPeriod()
        }
        
        await positionsObservable.ensureStartPosition(startPrice: NSDecimalNumber(decimal: 0), endPrice: Constants.startFunds)
        await positionsObservable.recalculateFunds(currentPeriod)
        await MainActor.run {
            positionsObservable.checkEndSessionCondition(currentPeriod)
        }
    }
}
