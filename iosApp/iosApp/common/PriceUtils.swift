import Foundation

public func int64PriceToString(_ price: Int64) -> String {
    var s = String(price)
    if (s.count > 2) {
        s.insert(".", at: s.index(s.endIndex, offsetBy: -2))
    } else if (s.count == 2) {
        s.insert(contentsOf: "0.", at: s.startIndex)
    } else if (s.count == 1) {
        s.insert(contentsOf: "0.0", at: s.startIndex)
    }
    return s
}

public func decimalPriceToString(_ value: NSDecimalNumber, _ minimumFractionDigits: Int = 2, showSign: Bool = false) -> String {
    let fmt = NumberFormatter()
    fmt.numberStyle = .none
    fmt.minimumFractionDigits = minimumFractionDigits
    fmt.minimumIntegerDigits = 1
    fmt.roundingMode = .halfUp
    if (showSign) {
        fmt.positivePrefix = fmt.plusSign
    }
    return fmt.string(from: value) ?? "0.00"
} 

public func getPercentDiff(_ value1: NSDecimalNumber, _ value2: NSDecimalNumber) -> NSDecimalNumber {
    let diff = value2.subtracting(value1)
    let pct = value1.dividing(by: NSDecimalNumber(integerLiteral: 100))
    return diff.dividing(by: pct)
}

public func getPositionResultInPct(_ p: Position, _ currentPriceCents: Int64) -> NSDecimalNumber {
    var positionValue = NSDecimalNumber.zero
    if (p.closed) {
        positionValue = calculateClosedPostionValue(p)
    } else {
        positionValue = calculateOpenPositionValue(currentPriceCents, p)
    }
    return getPercentDiff(p.totalSpent ?? NSDecimalNumber.zero, positionValue)
}


