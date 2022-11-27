import Foundation


class LongCommand : Command {
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject) {
        let currentPeriod = chartObservableObject.currentPeriod()
        let currentPeriodIndex = Int32(chartObservableObject.currentPeriodIndex())
        Task {
            await positionsObservableObject.openNewPosition(currentPeriod,
                                                            currentPeriodIndex,
                                                            isLongPosition: true)
            await positionsObservableObject.recalculateFunds(currentPeriod)
        }
    }
}

