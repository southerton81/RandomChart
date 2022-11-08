import Foundation

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
    
    public func subtractingPct(pctValue: NSDecimalNumber) -> NSDecimalNumber {
        let pct = dividing(by: NSDecimalNumber(integerLiteral: 100))
        return subtracting(pct.multiplying(by: pctValue))
    }
    
    public func addingPct(pctValue: NSDecimalNumber) -> NSDecimalNumber {
        let pct = dividing(by: NSDecimalNumber(integerLiteral: 100))
        return adding(pct.multiplying(by: pctValue))
    }
    
    public func pct(pctValue: NSDecimalNumber) -> NSDecimalNumber {
        let pct = dividing(by: NSDecimalNumber(integerLiteral: 100))
        return pct.multiplying(by: pctValue)
    }
    
    var absValue: Self { .init(decimal: decimalValue.magnitude) }
}
