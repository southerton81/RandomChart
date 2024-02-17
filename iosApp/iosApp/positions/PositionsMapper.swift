import Foundation
import CoreData
import SwiftUI

func mapToUiPosition(_ position: Position, _ currentPriceCents: Int64) -> UiPosition {
    let titleText = position.closed ? decimalToString(position.startPrice ?? NSDecimalNumber.zero) + " / " + decimalToString(position.endPrice ?? NSDecimalNumber.zero) : decimalToString(position.startPrice ?? NSDecimalNumber.zero)
    
    let typeText = position.long ? "Long" : "Short"
    let uiActionButton = position.closed ? nil : UiActionButton(caption: "Close", color: Color.blue)
    
    let lastPositionPrice = position.closed ? position.endPrice! : NSDecimalNumber(decimal: Decimal(currentPriceCents) / Decimal(100))
    let positionResult = getPositionResult(position, currentPriceCents)
    let positionResultPct = getPositionResultInPct(position.totalSpent, positionResult)
     
    let positionResultText = decimalToString(positionResultPct, 2, showSign: true) + "%"
    let positionValueText = decimalToString(positionResult, 0, showSign: false)
    let resultColor = (positionResultPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color(UIColor.systemRed) : Color(UIColor.systemGreen)
    return UiPosition(id: position.objectID,
                      startPeriod: position.startPeriod,
                      endPeriod: position.endPeriod,
                      titleText: titleText,
                      typeText: typeText,
                      positionValueText: positionValueText,
                      tradeResultText: positionResultText,
                      tradeResultTextColor: resultColor,
                      action: uiActionButton
    )
}

func mapToUiClosedPosition(_ position: Position) -> UiPosition {
    let titleText = decimalToString(position.endPrice ?? NSDecimalNumber.zero, 0)
    
    let typeText = position.long ? "Long" : "Short"
    let uiActionButton = position.closed ? nil : UiActionButton(caption: "Close", color: Color.blue)
    
    let lastPositionPrice = position.endPrice!
    
    let positionResult = getPositionResult(position)
    let positionResultPct = getPositionResultInPct(position.totalSpent, positionResult)
    
    let positionResultText = decimalToString(positionResultPct, 2, showSign: true) + "%"
    let positionValueText = decimalToString(positionResult, 0, showSign: false)
    let resultColor = (positionResultPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color(UIColor.systemRed) : Color(UIColor.systemGreen)
    return UiPosition(id: position.objectID,
                      startPeriod: position.startPeriod,
                      endPeriod: position.endPeriod,
                      titleText: titleText,
                      typeText: typeText,
                      positionValueText: positionValueText,
                      tradeResultText: positionResultText,
                      tradeResultTextColor: resultColor,
                      action: uiActionButton
    )
}
