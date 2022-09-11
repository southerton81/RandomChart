import Foundation
import CoreData

class ClosePositionCommand: Command {
    typealias ParamType = Double
    
    let container: PersistentContainer
    let chartObservableObject: ChartObservableObject
    let positionsObservableObject: PositionsObservableObject
    
    init(_ c: PersistentContainer, _ chartObservable: ChartObservableObject, _ positionObservable: PositionsObservableObject) {
        self.container = c
        self.positionsObservableObject = positionObservable
        self.chartObservableObject = chartObservable
    }
    
    func execute(_ positionId: NSManagedObjectID) {
        self.positionsObservableObject.close(self.container, positionId, self.chartObservableObject.currentPriceCents(),
                                             Int32(self.chartObservableObject.lastPeriodIndex()))
    }
}
