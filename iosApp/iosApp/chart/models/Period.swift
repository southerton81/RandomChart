import Foundation

class Period {
    let index: Int64
    let high: Int64
    let low: Int64
    let open: Int64
    let close: Int64
    
    init(index: Int64, high: Int64, low: Int64, open: Int64, close: Int64) {
        self.index = index
        self.high = high
        self.low = low
        self.open = open
        self.close = close
    }
}
