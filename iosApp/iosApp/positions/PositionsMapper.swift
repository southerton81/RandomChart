import Foundation
import CoreData
import SwiftUI

func mapToUiPosition(_ position: Position, _ currentPriceCents: Int64) -> UiPosition {
    let titleText = position.closed ? decimalToString(position.startPrice ?? NSDecimalNumber.zero) + " / " + decimalToString(position.endPrice ?? NSDecimalNumber.zero) : decimalToString(position.startPrice ?? NSDecimalNumber.zero)
    
    let typeText = position.long ? "Long" : "Short"
    let uiActionButton = position.closed ? nil : UiActionButton(caption: "Close", color: Color.blue)
    
    let lastPositionPrice = position.closed ? position.endPrice! : NSDecimalNumber(decimal: Decimal(currentPriceCents) / Decimal(100))
    let resultPct = getPositionResultInPct(position, currentPriceCents)
    
    let resultText = decimalToString(resultPct, 2, showSign: true) + "%"
    let resultColor = (resultPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color(UIColor.systemRed) : Color(UIColor.systemGreen)
    return UiPosition(id: position.objectID,
                      startPeriod: position.startPeriod,
                      endPeriod: position.endPeriod,
                      titleText: titleText,
                      typeText: typeText,
                      tradeResultText: resultText,
                      tradeResultTextColor: resultColor,
                      action: uiActionButton
    )
}

func mapToUiClosedPosition(_ position: Position) -> UiPosition {
    let titleText = decimalToString(position.endPrice ?? NSDecimalNumber.zero)
    
    let typeText = position.long ? "Long" : "Short"
    let uiActionButton = position.closed ? nil : UiActionButton(caption: "Close", color: Color.blue)
    
    let lastPositionPrice = position.endPrice!
    let resultPct = getPositionResultInPct(position, 0)
    
    let resultText = decimalToString(resultPct, 2, showSign: true) + "%"
    let resultColor = (resultPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color(UIColor.systemRed) : Color(UIColor.systemGreen)
    return UiPosition(id: position.objectID,
                      startPeriod: position.startPeriod,
                      endPeriod: position.endPeriod,
                      titleText: titleText,
                      typeText: typeText,
                      tradeResultText: resultText,
                      tradeResultTextColor: resultColor,
                      action: uiActionButton
    )
}
