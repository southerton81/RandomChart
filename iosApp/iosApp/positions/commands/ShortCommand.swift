import Foundation

class ShortCommand: Command {
    typealias ParamType = Double
    
    let container: PersistentContainer
    let chartObservableObject: ChartObservableObject
    let positionsObservableObject: PositionsObservableObject
    
    init(_ c: PersistentContainer, _ chartObservable: ChartObservableObject, _ positionObservable: PositionsObservableObject) {
        self.container = c
        self.positionsObservableObject = positionObservable
        self.chartObservableObject = chartObservable
    }
    
    func execute() {
        self.positionsObservableObject.openNewPosition(self.container, self.chartObservableObject.currentPriceCents(),
                                                       self.chartObservableObject.lastPeriodIndex(),
                                                       isLongPosition: false)
    }
}
