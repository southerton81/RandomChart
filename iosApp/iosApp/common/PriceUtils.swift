import Foundation

public func formatPrice(_ price: Int64) -> String {
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

public func decimalToString(_ value: NSDecimalNumber, _ minimumFractionDigits: Int = 2, showSign: Bool = false) -> String {
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

public func getPercentDiff(value1: NSDecimalNumber, value2: NSDecimalNumber, negative: Bool) -> NSDecimalNumber {
    let diff = value2.subtracting(value1)
    let pct = value1.dividing(by: NSDecimalNumber(integerLiteral: 100))
    let result = diff.dividing(by: pct)
    return negative ? NSDecimalNumber.zero.subtracting(result) : result
}

extension NSDecimalNumber {
    public func floorToInt64() -> Int64 {
        let roundingBehavior = NSDecimalNumberHandler(roundingMode: .down,
                                                      scale: 0,
                                                      raiseOnExactness: true,
                                                      raiseOnOverflow: true,
                                                      raiseOnUnderflow: true,
                                                      raiseOnDivideByZero: true)
        let rounded = rounding(accordingToBehavior: roundingBehavior)
        return rounded.int64Value
    }
}




