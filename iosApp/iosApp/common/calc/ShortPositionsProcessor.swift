import Foundation
import CoreData

func applyShortsInterestRates(_ c: CoreDataInventory, _ currentPeriod: Period) async {
    await c.performWrite(block: { c in
        let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
        let shortPositions = NSPredicate(format: "%K == false", #keyPath(Position.long))
        let openedPositions = NSPredicate(format: "%K == false", #keyPath(Position.closed))
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [shortPositions, openedPositions])
        let shortOpenPositions = try? fetchRequest.execute()
        shortOpenPositions?.forEach { p in
            let price = NSDecimalNumber(value: currentPeriod.close).dividing(by: 100)
            let totalValue = p.quantity?.multiplying(by: price)
            p.shortFee = p.shortFee?.adding(totalValue?.pct(pctValue: Constants.shortInterestRatePct) ?? NSDecimalNumber.zero)
            maybeLiquidateShort(currentPeriod, p)
        }
    })
}

/**
 * If high position price is leading to >= shortLiquidationPct% loss, position will be liquidated.
 * Price of liquidation is selected from position.low to position.high to closely match % result.
 */
private func maybeLiquidateShort(_ currentPeriod: Period, _ p: Position, _ shortLiquidationPct: NSDecimalNumber = NSDecimalNumber(-98)) {
    let positionHighPct = getPositionResultInPct(p, currentPeriod.high)
    
    if (positionHighPct.decimalValue.isLessThanOrEqualTo(shortLiquidationPct.decimalValue)) {
        let positionLowPct = getPositionResultInPct(p, currentPeriod.low)
        
        let priceRange = NSDecimalNumber(value: (currentPeriod.high - currentPeriod.low)).dividing(by: 100)
        
        var pctRange = positionHighPct.subtracting(positionLowPct).absValue
        if (pctRange == NSDecimalNumber.zero) {
            pctRange = NSDecimalNumber.one
        }
        
        let deltaPct = shortLiquidationPct.subtracting(positionLowPct).absValue
        
        let pct = deltaPct.dividing(by: pctRange).multiplying(by: 100)
        let priceToAdd = priceRange.dividing(by: NSDecimalNumber(100).dividing(by: pct)).absValue
        
        let lowPrice = NSDecimalNumber(value: currentPeriod.low).dividing(by: 100)
        var liquidationPrice = lowPrice.adding(priceToAdd)
        
        let highPrice = NSDecimalNumber(value: currentPeriod.high).dividing(by: 100)
        if (highPrice.decimalValue.isLess(than: liquidationPrice.decimalValue)) {
            liquidationPrice = highPrice
        }
        
        p.endPrice = liquidationPrice
        p.endPeriod = Int32(currentPeriod.index)
        p.closed = true
        
        print("priceRange ", priceRange.stringValue)
        print("positionHighPct ", positionHighPct.stringValue)
        print("positionLowPct ", positionLowPct.stringValue)
        print("pct ", pct.stringValue)
        print("priceToadd ", priceToAdd.stringValue)
        print("deltaPct ", deltaPct)
        print("pctRange ", pctRange.stringValue)
        print("liquidationPrice ", liquidationPrice.stringValue)
        print ("p ", getPositionResultInPct(p, liquidationPrice.multiplying(by: 100).int64Value).stringValue)
    }
}
