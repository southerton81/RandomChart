import Foundation
import SwiftUI

class NextCommand: Command {
    typealias ParamType = Double
    
    let container: PersistentContainer
    let chartObservableObject: ChartObservableObject
    let positionsObservableObject: PositionsObservableObject
    
    init(_ c: PersistentContainer, _ chartObservable: ChartObservableObject, _ positionObservable: PositionsObservableObject) {
        self.container = c
        self.positionsObservableObject = positionObservable
        self.chartObservableObject = chartObservable
    }
    
     func execute(_ positionSize: Double) {
        if (!self.positionsObservableObject.calculating) {
            currentOffset = self.chartObservableObject.next(currentOffset)
            self.chartObservableObject.saveChartState(self.container, {
                self.positionsObservableObject.recalculatePositionSize(positionSize)
                self.positionsObservableObject.recalculateFunds(self.container, self.chartObservableObject.currentPriceCents(), true)
            })
        }
    }
}
