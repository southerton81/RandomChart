import Foundation
import CoreData

class PositionsObservableObject: ObservableObject {
    @Published var totalCap: NSDecimalNumber = NSDecimalNumber.zero
    @Published var canOpenNewPos: Bool = false
    var positionSize = NSDecimalNumber(20_000)
    var freeFunds: NSDecimalNumber = NSDecimalNumber.zero
    
    func recalculatePositionSize(_ positionSizePct: Double) -> NSDecimalNumber {
        positionSize = totalCap.dividing(by: NSDecimalNumber(100)).multiplying(by: NSDecimalNumber(value: positionSizePct))
        return positionSize
    }
    
    func recalculateFunds(_ c: PersistentContainer, _ currentPriceCent: Int64 = 0) {
        let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startPeriod", ascending: true)]
 
        if var positions = try? c.context().fetch(fetchRequest) {
            if (positions.isEmpty) {
                createStartingFundsPosition(c, fetchRequest, &positions)
            }
            
            let closedPositionsValue = positions
                .filter({ p in p.closed == true })
                .map({ p in
                    return calculateClosedPostionValue(p)
                }).reduce(NSDecimalNumber.zero) { result, next in
                    result.adding(next)
            }
            
            let openPositionsValue = positions
                .filter({ p in p.closed == false })
                .map({ p in
                    return calculateOpenPositionValue(currentPriceCent, p)
                }).reduce(NSDecimalNumber.zero) { result, next in
                    result.adding(next)
            }
            
            let positionsCost = positions
                .map({ p in
                    p.quantity?.multiplying(by: p.startPrice ?? 0) ?? 0
                }).reduce(NSDecimalNumber.zero) { result, next in
                    result.adding(next)
            }
            
            freeFunds = closedPositionsValue.subtracting(positionsCost)
            totalCap = closedPositionsValue.subtracting(positionsCost).adding(openPositionsValue)
            canOpenNewPos = canOpenNewPosition()
        }
    }
    
    func openNewPosition(_ c: PersistentContainer, _ currentPriceCent: Int64, _ startPeriod: Int32, isLongPosition: Bool) {
        let price = NSDecimalNumber(value: currentPriceCent).dividing(by: 100)
        let boughtQuantity = positionSize.dividing(by: price)
        let newPosition = Position(context: c.context())
        newPosition.closed = false
        newPosition.startPrice = price
        newPosition.quantity = boughtQuantity
        newPosition.startPeriod = startPeriod
        newPosition.long = isLongPosition
        c.saveContext()
        
        recalculateFunds(c, currentPriceCent)
    }
    
    func close(_ c: PersistentContainer, _ position: Position, _ currentPriceCent: Int64, _ endPeriod: Int32) {
        let price = NSDecimalNumber(value: currentPriceCent).dividing(by: 100)
        position.closed = true
        position.endPrice = price
        position.endPeriod = endPeriod
        c.saveContext()
        
        recalculateFunds(c, currentPriceCent)
    }
    
    func canOpenNewPosition() -> Bool {
        let comparisonResult = freeFunds.compare(positionSize)
        return comparisonResult == ComparisonResult.orderedDescending || comparisonResult == ComparisonResult.orderedSame
    }
    
    fileprivate func calculateClosedPostionValue(_ p: Position) -> NSDecimalNumber {
        if let startPrice = p.startPrice, let endPrice = p.endPrice {
            if (!p.long) {
                if let closedPositionValue = p.quantity?.multiplying(by: endPrice) {
                    if let openPositionValue = p.quantity?.multiplying(by: startPrice) {
                        let shortPositionResult = openPositionValue.adding(openPositionValue.subtracting(closedPositionValue))
                        return shortPositionResult
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
    
    fileprivate func calculateOpenPositionValue(_ currentPriceCent: Int64, _ p: Position) -> NSDecimalNumber {
        let currentPriceDollar = NSDecimalNumber(value: currentPriceCent).dividing(by: NSDecimalNumber(100))
        
        if (!p.long) {
            if let quantity = p.quantity {
                let positionCurrentValue = quantity.multiplying(by: currentPriceDollar)
                let positionOpenValue = quantity.multiplying(by: p.startPrice ?? 0)
                let shortPositionOpenResult = positionOpenValue.adding(positionOpenValue.subtracting(positionCurrentValue))
                return shortPositionOpenResult
            }
        } else {
            if let quantity = p.quantity {
                let positionCurrentValue = quantity.multiplying(by: currentPriceDollar)
                return positionCurrentValue
            }
        }
        return NSDecimalNumber.zero
    }
    
    fileprivate func createStartingFundsPosition(_ c: PersistentContainer, _ fetchRequest: NSFetchRequest<Position>, _ positions: inout [Position]) {
        let startingFundsPosition = Position(context: c.context())
        startingFundsPosition.closed = true
        startingFundsPosition.startPrice = NSDecimalNumber(decimal: 0)
        startingFundsPosition.endPrice = NSDecimalNumber(decimal: 100_000)
        startingFundsPosition.quantity = 1
        startingFundsPosition.startPeriod = -1
        startingFundsPosition.long = true
        c.saveContext()
        let updatedPositions = try? c.context().fetch(fetchRequest)
        positions = updatedPositions ?? positions
    }
}
