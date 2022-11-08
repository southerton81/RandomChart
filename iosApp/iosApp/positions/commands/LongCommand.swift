import Foundation


class LongCommand: Command {
    typealias ParamType = Void
    
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject) {
        positionsObservableObject.openNewPosition(chartObservableObject.currentPeriod(),
                                                  chartObservableObject.currentPeriodIndex(),
                                                  isLongPosition: true)
    }
}

