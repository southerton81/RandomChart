import Foundation
import CoreData
import SwiftUI

class PositionsObservableObject: ObservableObject {
    @Published var totalCap = NSDecimalNumber.zero
    @Published var canOpenNewPos = false
    @Published var calculating = true
    @Published var endSessionCondition: EndSessionCondition? = nil
    @Published var positionSizePct: Double
    @Published var positionSize = NSDecimalNumber.zero 
    
    private let c: CoreDataInventory
    var freeFunds = NSDecimalNumber.zero
    
    init(_ c: CoreDataInventory) {
        self.c = c
        self.positionSizePct = readPositionSize()
    }
    
    func recalculatePositionSize(_ positionSizePct: Double) {
        savePositionSize(positionSizePct: positionSizePct)
        self.positionSizePct = positionSizePct
        self.positionSize = totalCap.dividing(by: NSDecimalNumber(100)).multiplying(by: NSDecimalNumber(value: self.positionSizePct))
        self.canOpenNewPos = canOpenNewPosition()
    }
    
    func maxPositionSizePct() -> Double {
        self.freeFunds.pctOf(otherValue: self.totalCap).doubleValue
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
            self.recalculatePositionSize(self.positionSizePct)
            self.canOpenNewPos = canOpenNewPosition()
            self.calculating = false
        }
    }
    
    func canOpenNewPosition() -> Bool {
        return freeFunds.floorToInt64() >= positionSize.floorToInt64() && freeFunds.floorToInt64() > 0
    }
    
    func openNewPosition(_ currentPeriod: Period, _ startPeriod: Int32, isLongPosition: Bool) async {
        if (canOpenNewPos) {
            await c.performWrite { c in
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
        }
    }
    
    func closePosition(_ positionId: NSManagedObjectID, _ currentPeriod: Period, _ currentPeriodIndex: Int32) async {
        await c.performWrite { c in
            let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
            fetchRequest.predicate = NSPredicate(format: "self == %@", positionId)
            let position = try? c.fetch(fetchRequest).first
            self.setPositionClosed(position, currentPeriod, currentPeriodIndex)
        }
    }
    
    private func setPositionClosed(_ position: Position?, _ currentPeriod: Period, _ currentPeriodIndex: Int32) {
        let price = NSDecimalNumber(value: currentPeriod.close).dividing(by: 100)
        position?.closed = true
        position?.endPrice = price
        position?.endPeriod = currentPeriodIndex
        
        if (position?.long ?? true) {
            position?.quantity = position?.quantity?.subtractingPct(pctValue: Constants.feePct)
        } else {
            let totalValue = position?.quantity?.multiplying(by: price)
            position?.shortFee = position?.shortFee?.adding(totalValue?.pct(pctValue: Constants.feePct) ?? NSDecimalNumber.zero)
        }
    }
    
    func ensureStartPosition(startPrice: NSDecimalNumber, endPrice: NSDecimalNumber) async {
        await c.performWrite(block: { c in
            let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
            let r = try? fetchRequest.execute()
            if (r?.isEmpty ?? false) {
                self.buildCheckpointPosition(c, startPrice, endPrice)
            }
        })
    }

    
    func closeAllPositions(_ currentPeriod: Period, _ currentPeriodIndex: Int32) async {
        await c.performWrite { c in
            let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
            fetchRequest.predicate = NSPredicate(format: "%K == false", #keyPath(Position.closed))
            
            if let openPositions = try? fetchRequest.execute() {
                openPositions.forEach { p in
                    self.setPositionClosed(p, currentPeriod, currentPeriodIndex)
                }
            }
        }
    }
    
    private func buildCheckpointPosition(_ c: NSManagedObjectContext, _ startPrice: NSDecimalNumber, _ endPrice: NSDecimalNumber) {
        let startingFundsPosition = Position(context: c)
        startingFundsPosition.closed = true
        startingFundsPosition.startPrice = startPrice
        startingFundsPosition.endPrice = endPrice
        startingFundsPosition.quantity = 1
        startingFundsPosition.startPeriod = -1
        startingFundsPosition.creationDate = Date()
        startingFundsPosition.totalSpent = startPrice
        startingFundsPosition.long = true
    }
    
    func reduceSessionPositions(_ currentPeriod: Period, _ currentPeriodIndex: Int32) async {
        await c.performWrite { context in
            // Delete all in session positions
            let sessionPositionsRequest = NSFetchRequest<Position>(entityName: "Position")
            sessionPositionsRequest.predicate = NSPredicate(format: "%K != -1", #keyPath(Position.startPeriod))
            let positionsToDelete = try! context.fetch(sessionPositionsRequest)
            for position in positionsToDelete {
                context.delete(position)
            }

            // Get start price from recent checkpoint
            let fetchLastCheckpointPosition = NSFetchRequest<Position>(entityName: "Position")
            fetchLastCheckpointPosition.fetchLimit = 1
            fetchLastCheckpointPosition.sortDescriptors = [NSSortDescriptor(keyPath: \Position.creationDate, ascending: false)]
            let startPrice = try! fetchLastCheckpointPosition.execute().first?.endPrice ?? 0
            
            // Create new checkpoint to contain session result
            self.buildCheckpointPosition(context, startPrice, self.totalCap)
        }
    }
    
    func recalculateLastSessionProfitPct(_ currentPeriod: Period) async -> NSDecimalNumber {
        return await c.performRead { (c) -> (NSDecimalNumber) in
            let fetchLastCheckpointPosition = NSFetchRequest<Position>(entityName: "Position")
            fetchLastCheckpointPosition.fetchLimit = 2
            fetchLastCheckpointPosition.sortDescriptors = [NSSortDescriptor(keyPath: \Position.creationDate, ascending: false)]
            
            let result = try? fetchLastCheckpointPosition.execute()
            
            if (result?.count ?? 0 > 1) {
                let currentPosition = result?[0].endPrice ?? NSDecimalNumber.zero
                let lastPosition = result?[1].endPrice ?? NSDecimalNumber.zero
                return getDifferenceInPct(lastPosition, currentPosition)
            } else {
                return NSDecimalNumber.zero
            }
        }
    }
    
    func maybeSetEndSessionCondition(_ currentPeriod: Period, reset: Bool = false) -> Bool {
        var endSessionCondition: EndSessionCondition? = nil
        
        if reset {
            endSessionCondition = EndSessionCondition.ResetChart
        }
        if currentPeriod.index >= Constants.sessionLength {
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

        return self.endSessionCondition != nil
    }
    
    enum EndSessionCondition: String {
        case TimeOver = "Session time is over"
        case FundsOver = "Not enough funds"
        case CompanyOver = "Company is delisted"
        case ResetChart = "Results"
    }
}
