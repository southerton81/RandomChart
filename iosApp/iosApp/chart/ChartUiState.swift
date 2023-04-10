import Foundation

class ChartUiState {
    static let shared = ChartUiState()

    private init() {}
    
    var lastDrag: CGFloat? = nil
    var lastMagnitude: CGFloat? = nil
    var currentOffset: CGFloat = 0
}
