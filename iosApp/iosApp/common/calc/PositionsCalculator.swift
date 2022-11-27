import Foundation
import CoreData

struct FundsResult {
    let totalCap: NSDecimalNumber
    let freeCap: NSDecimalNumber
}

func calculateTotalFunds(_ c: CoreDataInventory, _ currentPriceCent: Int64) async -> FundsResult {
    return await c.performRead { (c) -> FundsResult in
        let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startPeriod", ascending: true)]
        
        if let positions = try? fetchRequest.execute() {
            
            let closedPositionsValue = positions
                .filter({ p in p.closed == true })
                .map({ p in
                    calculateClosedPostionValue(p)
                }).reduce(NSDecimalNumber.zero) { result, next in
                    result.adding(next)
                }
            
            let openPositionsValue = positions
                .filter({ p in p.closed == false })
                .map({ p in
                    calculateOpenPositionValue(currentPriceCent, p)
                }).reduce(NSDecimalNumber.zero) { result, next in
                    result.adding(next)
                }
            
            let positionsCost = positions
                .map({ p in
                    p.totalSpent ?? 0
                }).reduce(NSDecimalNumber.zero) { result, next in
                    result.adding(next)
                }
            
            return FundsResult(totalCap: closedPositionsValue.subtracting(positionsCost).adding(openPositionsValue),
                               freeCap: closedPositionsValue.subtracting(positionsCost))
        }
        
        return FundsResult(totalCap: NSDecimalNumber.zero, freeCap: NSDecimalNumber.zero)
    }
}

func calculateClosedPostionValue(_ p: Position) -> NSDecimalNumber {
    if let startPrice = p.startPrice, let endPrice = p.endPrice {
        if (!p.long) {
            if let closedPositionValue = p.quantity?.multiplying(by: endPrice) {
                if let openPositionValue = p.quantity?.multiplying(by: startPrice) {
                    let closedShortPositionValue = openPositionValue.adding(openPositionValue.subtracting(closedPositionValue)).subtracting(p.shortFee ?? 0)
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
            let shortPositionCurrentValue = positionOpenValue.adding(positionOpenValue.subtracting(positionCurrentValue)).subtracting(p.shortFee ?? 0)
            return shortPositionCurrentValue
        }
    } else {
        if let positionCurrentValue = p.quantity?.multiplying(by: currentPriceDollar) {
            return positionCurrentValue
        }
    }
    return NSDecimalNumber.zero
}

func getDifferenceInPct(_ value1: NSDecimalNumber, _ value2: NSDecimalNumber) -> NSDecimalNumber {
    let diff = value2.subtracting(value1)
    let pct = value1.dividing(by: NSDecimalNumber(integerLiteral: 100))
    return diff.dividing(by: pct)
}

func getPositionResultInPct(_ p: Position, _ currentPriceCents: Int64) -> NSDecimalNumber {
    var positionValue = NSDecimalNumber.zero
    if (p.closed) {
        positionValue = calculateClosedPostionValue(p)
    } else {
        positionValue = calculateOpenPositionValue(currentPriceCents, p)
    }
    return getDifferenceInPct(p.totalSpent ?? NSDecimalNumber.zero, positionValue)
}
