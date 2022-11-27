import Foundation
import CoreData

class ClosePositionCommand : Command {
    func execute(_ positionsObservableObject: PositionsObservableObject,
                 _ chartObservableObject: ChartObservableObject,
                 _ positionId: NSManagedObjectID) {
        let currentPeriod = chartObservableObject.currentPeriod()
        let currentPeriodIndex = Int32(chartObservableObject.currentPeriodIndex())
        Task {
            await positionsObservableObject.closePosition(positionId, currentPeriod, currentPeriodIndex)
            await positionsObservableObject.recalculateFunds(currentPeriod)
        }
    }
}
