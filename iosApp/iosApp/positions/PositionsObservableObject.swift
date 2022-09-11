import Foundation
import CoreData

class PositionsObservableObject: ObservableObject {
    @Published var totalCap = NSDecimalNumber.zero
    @Published var canOpenNewPos = false
    @Published var calculating = false
    
    private let startFunds = NSDecimalNumber(decimal: 100_000)
    var positionSize = NSDecimalNumber(20_000)
    var freeFunds = NSDecimalNumber.zero
    let feePct = NSDecimalNumber(string: "0.01")
    let shortCostPct = NSDecimalNumber(string: "0.8")
    var time: Int64 = 0
    
    func recalculatePositionSize(_ positionSizePct: Double) -> NSDecimalNumber {
        positionSize = totalCap.dividing(by: NSDecimalNumber(100)).multiplying(by: NSDecimalNumber(value: positionSizePct))
        return positionSize
    }
    
    struct FundsFetchResult {
        let totalCap: NSDecimalNumber
        let freeCap: NSDecimalNumber
    }
    
    func recalculateFunds(_ c: PersistentContainer, _ currentPriceCent: Int64 = 0, _ applyShortPositionsCost: Bool = false) {
        calculating = true
        canOpenNewPos = false
        
        Task {
            if (applyShortPositionsCost) {
               await applyShortsCost(c)
            }
            
            let fundsFetchResult = await c.sharedBackgroundContext()
                .perform(schedule: NSManagedObjectContext.ScheduledTaskType.immediate) { () -> FundsFetchResult in
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
                        
                        return FundsFetchResult(totalCap:
                                                    closedPositionsValue.subtracting(positionsCost).adding(openPositionsValue),
                                                freeCap:
                                                    closedPositionsValue.subtracting(positionsCost))
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
    
    private func applyShortsCost(_ c: PersistentContainer) async {
        await c.sharedBackgroundContext()
            .perform(schedule: NSManagedObjectContext.ScheduledTaskType.immediate) { () -> _ in
                let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
                
                let p0 = NSPredicate(format: "%K == false", #keyPath(Position.long))
                let p1 = NSPredicate(format: "%K == false", #keyPath(Position.closed))
                
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p0, p1])
                
                if let shortOpenPositions = try? fetchRequest.execute() {
                    c.saveContext(block: { c in
                        shortOpenPositions.forEach { p in
                            p.quantity = p.quantity?.subtractingPct(pctValue: self.shortCostPct)
                        }
                    })
                }
            }
    }
    
    func openNewPosition(_ c: PersistentContainer, _ currentPriceCent: Int64, _ startPeriod: Int32, isLongPosition: Bool) {
        if (canOpenNewPos) {
            c.saveContext { c in
                let price = NSDecimalNumber(value: currentPriceCent).dividing(by: 100)
                
                let fee = self.positionSize.dividing(by: NSDecimalNumber(integerLiteral: 100)).multiplying(by: self.feePct)
                let positionSizeAfterFee = self.positionSize.subtracting(fee)
                
                let boughtQuantity = positionSizeAfterFee.dividing(by: price)
                let newPosition = Position(context: c)
                newPosition.totalSpent = self.positionSize
                newPosition.closed = false
                newPosition.startPrice = price
                newPosition.quantity = boughtQuantity
                newPosition.startPeriod = startPeriod
                newPosition.long = isLongPosition
                newPosition.creationDate = Date()
            }
            
            recalculateFunds(c, currentPriceCent)
        }
    }
    
    func close(_ c: PersistentContainer, _ positionId: NSManagedObjectID, _ currentPriceCent: Int64, _ endPeriod: Int32) {
        if (!calculating) {
            c.saveContext { c in
                let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
                fetchRequest.predicate = NSPredicate(format: "self == %@", positionId)
                let position = try? c.fetch(fetchRequest).first
                
                let price = NSDecimalNumber(value: currentPriceCent).dividing(by: 100)
                position?.closed = true
                position?.endPrice = price
                position?.endPeriod = endPeriod
                position?.quantity = position?.quantity?.subtractingPct(pctValue: self.feePct)
            }
            
            recalculateFunds(c, currentPriceCent)
        }
    }
    
    func canOpenNewPosition() -> Bool {
        let comparisonResult = freeFunds.compare(positionSize)
        return comparisonResult == ComparisonResult.orderedDescending || comparisonResult == ComparisonResult.orderedSame
    }
    
    func createStartingFundsPosition(_ c: PersistentContainer, _ next: @escaping () -> Void) {
        c.saveContext(block: { c in
            let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
            let r = try? fetchRequest.execute()
            
            if (r?.isEmpty ?? false) {
                let startingFundsPosition = Position(context: c)
                startingFundsPosition.closed = true
                startingFundsPosition.startPrice = NSDecimalNumber(decimal: 0)
                startingFundsPosition.endPrice = self.startFunds
                startingFundsPosition.quantity = 1
                startingFundsPosition.startPeriod = -1
                startingFundsPosition.creationDate = Date()
                startingFundsPosition.long = true
            }
        }, next)
    }
    
    func getTime() -> Int64 {
        self.time += 1
        return self.time
    }
}
