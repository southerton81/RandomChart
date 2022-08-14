import Foundation
import CoreData

class PositionsObservableObject: ObservableObject {
    @Published var totalCap = NSDecimalNumber.zero
    @Published var canOpenNewPos = false
    @Published var calculating = false
    
    private let startFunds = NSDecimalNumber(decimal: 100_000)
    var positionSize = NSDecimalNumber(20_000)
    var freeFunds = NSDecimalNumber.zero
    
    func recalculatePositionSize(_ positionSizePct: Double) -> NSDecimalNumber {
        positionSize = totalCap.dividing(by: NSDecimalNumber(100)).multiplying(by: NSDecimalNumber(value: positionSizePct))
        return positionSize
    }
    
    struct FundsFetchResult {
        let totalCap: NSDecimalNumber
        let freeCap: NSDecimalNumber
    }
    
    func recalculateFunds(_ c: PersistentContainer, _ currentPriceCent: Int64 = 0) {
        calculating = true
        canOpenNewPos = false
        Task {
            let fundsFetchResult = await c.sharedBackgroundContext().perform(schedule: NSManagedObjectContext.ScheduledTaskType.immediate) { () -> FundsFetchResult in
                let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startPeriod", ascending: true)]
                
                if var positions = try? fetchRequest.execute() {
                    if (positions.isEmpty) {
                        self.createStartingFundsPosition(c, fetchRequest, &positions)
                    }
                    
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
                            calculateOpenPositionCurrentValue(currentPriceCent, p)
                        }).reduce(NSDecimalNumber.zero) { result, next in
                            result.adding(next)
                        }
                    
                    let positionsCost = positions
                        .map({ p in
                            p.quantity?.multiplying(by: p.startPrice ?? 0) ?? 0
                        }).reduce(NSDecimalNumber.zero) { result, next in
                            result.adding(next)
                        }
                    
                    return FundsFetchResult(totalCap: closedPositionsValue.subtracting(positionsCost).adding(openPositionsValue),
                                            freeCap: closedPositionsValue.subtracting(positionsCost))
                }
                
                return FundsFetchResult(totalCap: NSDecimalNumber.zero, freeCap: NSDecimalNumber.zero)
            }
            
            await MainActor.run {
                self.totalCap = fundsFetchResult.totalCap
                self.freeFunds = fundsFetchResult.freeCap
                self.canOpenNewPos = canOpenNewPosition()
                self.calculating = false
            }
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
        c.saveContext(c.context())
        
        recalculateFunds(c, currentPriceCent)
    }
    
    func close(_ c: PersistentContainer, _ position: Position, _ currentPriceCent: Int64, _ endPeriod: Int32) {
        let price = NSDecimalNumber(value: currentPriceCent).dividing(by: 100)
        position.closed = true
        position.endPrice = price
        position.endPeriod = endPeriod
        c.saveContext(c.context())
        
        recalculateFunds(c, currentPriceCent)
    }
    
    func canOpenNewPosition() -> Bool {
        let comparisonResult = freeFunds.compare(positionSize)
        return comparisonResult == ComparisonResult.orderedDescending || comparisonResult == ComparisonResult.orderedSame
    }
    
    fileprivate func createStartingFundsPosition(_ c: PersistentContainer, _ fetchRequest: NSFetchRequest<Position>, _ positions: inout [Position]) {
        let startingFundsPosition = Position(context: c.sharedBackgroundContext())
        startingFundsPosition.closed = true
        startingFundsPosition.startPrice = NSDecimalNumber(decimal: 0)
        startingFundsPosition.endPrice = startFunds
        startingFundsPosition.quantity = 1
        startingFundsPosition.startPeriod = -1
        startingFundsPosition.long = true
        c.saveContext(c.sharedBackgroundContext())
        let updatedPositions = try? c.sharedBackgroundContext().fetch(fetchRequest)
        positions = updatedPositions ?? positions
    }
}
