import Foundation

class ShortCommand: Command {
    typealias ParamType = Double
    
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject) {
        positionsObservableObject.openNewPosition(chartObservableObject.currentPeriod(),
                                                  chartObservableObject.currentPeriodIndex(),
                                                  isLongPosition: false)
    }
}
