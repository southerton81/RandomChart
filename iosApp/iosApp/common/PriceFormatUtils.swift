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
    fmt.roundingMode = .halfDown
    if (showSign) {
        fmt.positivePrefix = fmt.plusSign
    }
    return fmt.string(from: value) ?? "0.00"
}

