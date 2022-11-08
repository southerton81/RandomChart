import Foundation
import CoreData

class ClosePositionCommand: Command {
    typealias ParamType = Double
    
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject,
                 _ positionId: NSManagedObjectID) {
        positionsObservableObject.closePosition(positionId,
                                                chartObservableObject.currentPeriod(),
                                                Int32(chartObservableObject.currentPeriodIndex()))
    }
}
