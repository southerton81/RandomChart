import Foundation

class ShowPositionCommand : Command {
   func execute(_ chartObservable: ChartObservableObject, _ startIndex: Int32, _ endIndex: Int32) {
       if let offset = chartObservable.zoomToPosition(startIndex, endIndex) {
           ChartUiState.shared.currentOffset = offset
       }
   }
}
