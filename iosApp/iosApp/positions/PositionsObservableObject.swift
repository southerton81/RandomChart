import Foundation
import CoreData
import SwiftUI

class PositionsObservableObject: ObservableObject {
    @Published var totalCap = NSDecimalNumber.zero
    @Published var canOpenNewPos = false
    @Published var calculating = false
    @Published var endSessionCondition: EndSessionCondition? = nil
    private let c: CoreDataInventory
    
    var positionSize = NSDecimalNumber(20_000)
    var freeFunds = NSDecimalNumber.zero
    
    init(_ c: CoreDataInventory) {
        self.c = c
    }
    
    func recalculatePositionSize(_ positionSizePct: Double) -> NSDecimalNumber {
        positionSize = totalCap.dividing(by: NSDecimalNumber(100)).multiplying(by: NSDecimalNumber(value: positionSizePct))
        return positionSize
    }
    
    func recalculateFunds(_ currentPeriod: Period, _ applyShortPositionsCost: Bool = false) async {
        await MainActor.run {
            calculating = true
            canOpenNewPos = false
        }
        
        if (applyShortPositionsCost) {
            await applyShortsInterestRates(c, currentPeriod)
        }
        
        let fundsResult = await calculateTotalFunds(c, currentPeriod.close)
        
        await MainActor.run {
            self.totalCap = fundsResult.totalCap
            self.freeFunds = fundsResult.freeCap
            self.canOpenNewPos = canOpenNewPosition()
            self.calculating = false
        }
    }
    
    func checkEndSessionCondition(_ currentPeriod: Period) {
        var endSessionCondition: EndSessionCondition? = nil
        
        if currentPeriod.index == Constants.sessionLength {
            endSessionCondition = EndSessionCondition.TimeOver
        }
        if currentPeriod.close <= 0 {
            endSessionCondition = EndSessionCondition.CompanyOver
        }
        if self.totalCap.compare(Constants.minTotalCap) == ComparisonResult.orderedAscending &&
            self.totalCap.compare(self.freeFunds) == ComparisonResult.orderedSame {
            endSessionCondition = EndSessionCondition.FundsOver
        }
        self.endSessionCondition = endSessionCondition
    }
    
    func canOpenNewPosition() -> Bool {
        return freeFunds.floorToInt64() >= positionSize.floorToInt64() && freeFunds.floorToInt64() > 0
    }
    
    func openNewPosition(_ currentPeriod: Period, _ startPeriod: Int32, isLongPosition: Bool) {
        if (canOpenNewPos) {
            Task {
                await c.perform { c in
                    let price = NSDecimalNumber(value: currentPeriod.close).dividing(by: 100)
                    
                    let fee = self.positionSize.dividing(by: NSDecimalNumber(integerLiteral: 100)).multiplying(by: Constants.feePct)
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
                    
                    if (!isLongPosition) {
                        newPosition.shortFee = NSDecimalNumber.zero
                    }
                }
                
                await recalculateFunds(currentPeriod)
            }
        }
    }
    
    func closePosition(_ positionId: NSManagedObjectID, _ currentPeriod: Period, _ endPeriodIndex: Int32) {
        if (!calculating) {
            Task {
                await c.perform { c in
                    let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
                    fetchRequest.predicate = NSPredicate(format: "self == %@", positionId)
                    let position = try? c.fetch(fetchRequest).first
                    self.setPositionClosed(position, currentPeriod, endPeriodIndex)
                }
                
                await recalculateFunds(currentPeriod)
            }
        }
    }
    
    private func setPositionClosed(_ position: Position?, _ currentPeriod: Period, _ endPeriodIndex: Int32) {
        let price = NSDecimalNumber(value: currentPeriod.close).dividing(by: 100)
        position?.closed = true
        position?.endPrice = price
        position?.endPeriod = endPeriodIndex
        
        if (position?.long ?? true) {
            position?.quantity = position?.quantity?.subtractingPct(pctValue: Constants.feePct)
        } else {
            let totalValue = position?.quantity?.multiplying(by: price)
            position?.shortFee = position?.shortFee?.adding(totalValue?.pct(pctValue: Constants.feePct) ?? NSDecimalNumber.zero)
        }
    }
    
    func ensureStartPosition(startPrice: NSDecimalNumber, endPrice: NSDecimalNumber) async {
        await c.perform(block: { c in
            let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
            let r = try? fetchRequest.execute()
            if (r?.isEmpty ?? false) {
                self.buildCheckpointPosition(c, startPrice, endPrice)
            }
        })
    }
    
    private func buildCheckpointPosition(_ c: NSManagedObjectContext, _ startPrice: NSDecimalNumber, _ endPrice: NSDecimalNumber) {
        let startingFundsPosition = Position(context: c)
        startingFundsPosition.closed = true
        startingFundsPosition.startPrice = startPrice
        startingFundsPosition.endPrice = endPrice
        startingFundsPosition.quantity = 1
        startingFundsPosition.startPeriod = -1
        startingFundsPosition.creationDate = Date()
        startingFundsPosition.long = true
    }
    
    func endSession(_ currentPeriod: Period, _ endPeriod: Int32) {
        Task {
            //1. Close all positions
            /*await c.sharedBackgroundContext()
                .perform(schedule: NSManagedObjectContext.ScheduledTaskType.immediate) { () -> _ in
                    let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
                    fetchRequest.predicate = NSPredicate(format: "%K == false", #keyPath(Position.closed))
                    
                    if let openPositions = try? fetchRequest.execute() {
                        self.c.saveContext(block: { c in
                            openPositions.forEach { p in
                                self.setPositionClosed(p, currentPeriod, endPeriod)
                            }
                        })
                    }
                }
            
            //2. Zip positions to single
            await c.sharedBackgroundContext()
                .perform(schedule: NSManagedObjectContext.ScheduledTaskType.immediate) { () -> _ in
                    
                    let fetchLastCheckpointPosition = NSFetchRequest<Position>(entityName: "Position")
                    fetchLastCheckpointPosition.fetchLimit = 1
                    fetchLastCheckpointPosition.sortDescriptors = [NSSortDescriptor(keyPath: \Position.creationDate, ascending: false)]
                    
                    let sessionPositionsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Position")
                    sessionPositionsRequest.predicate = NSPredicate(format: "%K != -1", #keyPath(Position.startPeriod))
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: sessionPositionsRequest)
                    
                    self.c.saveContext(block: { context in
                        
                        // Remove all in-session positions
                        try! context.execute(deleteRequest)
                        
                        // Get start price from recent checkpoint
                        let startPrice = try! fetchLastCheckpointPosition.execute().first?.endPrice ?? 0
                        
                        // Create new checkpoint to contain session result
                        self.buildCheckpointPosition(context, startPrice, self.totalCap)
                    })
                }
            */
            //3. Reset
            
            
        }
    }
    
    enum EndSessionCondition: String {
        case TimeOver = "Session time is over"
        case FundsOver = "Not enough funds"
        case CompanyOver = "Company is gone bankrupt"
    }
}
