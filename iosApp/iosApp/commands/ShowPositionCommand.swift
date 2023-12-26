import Foundation
import SwiftUI

class ShowPositionCommand : Command {
   func execute(_ chartObservable: ChartObservableObject,
                _ startIndex: Int32,
                _ endIndex: Int32,
                _ positions: FetchedResults<Position>) {
       if let offset = chartObservable.zoomToPosition(startIndex, endIndex, positions) {
           ChartUiState.shared.currentOffset = offset
       }
   }
}
