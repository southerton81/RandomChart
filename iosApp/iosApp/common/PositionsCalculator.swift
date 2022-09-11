import Foundation

func calculateClosedPostionValue(_ p: Position) -> NSDecimalNumber {
    if let startPrice = p.startPrice, let endPrice = p.endPrice {
        if (!p.long) {
            if let closedPositionValue = p.quantity?.multiplying(by: endPrice) {
                if let openPositionValue = p.quantity?.multiplying(by: startPrice) {
                    let closedShortPositionValue = openPositionValue.adding(openPositionValue.subtracting(closedPositionValue))
                    return closedShortPositionValue
                }
            }
        } else {
            if let closedPositionValue = p.quantity?.multiplying(by: endPrice) {
                return closedPositionValue
            }
        }
    }
    return NSDecimalNumber.zero
}

func calculateOpenPositionValue(_ currentPriceCent: Int64, _ p: Position) -> NSDecimalNumber {
    let currentPriceDollar = NSDecimalNumber(value: currentPriceCent).dividing(by: NSDecimalNumber(100))
    
    if (!p.long) {
        if let quantity = p.quantity {
            let positionCurrentValue = quantity.multiplying(by: currentPriceDollar)
            let positionOpenValue = quantity.multiplying(by: p.startPrice ?? 0)
            let shortPositionCurrentValue = positionOpenValue.adding(positionOpenValue.subtracting(positionCurrentValue))
            return shortPositionCurrentValue
        }
    } else {
        if let positionCurrentValue = p.quantity?.multiplying(by: currentPriceDollar) {
            return positionCurrentValue
        }
    }
    return NSDecimalNumber.zero
}

func calculateOpenPositionStartValue(_ p: Position) -> NSDecimalNumber {
    if let startPrice = p.startPrice, let quantity = p.quantity {
        return quantity.multiplying(by: startPrice)
    }
    return NSDecimalNumber.zero
}

