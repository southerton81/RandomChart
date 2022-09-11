import Foundation
import CoreData
import SwiftUI

func mapToUiPosition(_ position: Position, _ currentPriceCents: Int64) -> UiPosition {
    let titleText = position.closed ? decimalPriceToString(position.startPrice ?? NSDecimalNumber.zero) + " / " + decimalPriceToString(position.endPrice ?? NSDecimalNumber.zero) : decimalPriceToString(position.startPrice ?? NSDecimalNumber.zero)
    let typeText = position.long ? "Long" : "Short"
    let uiActionButton = position.closed ? nil : UiActionButton(caption: "Close", color: Color.blue)
    
    let lastPositionPrice = position.closed ? position.endPrice! : NSDecimalNumber(decimal: Decimal(currentPriceCents) / Decimal(100))
    let resultPct = getPositionResultInPct(position, currentPriceCents)
    
    let resultText = decimalPriceToString(resultPct, 2, showSign: true) + "%"
    let resultColor = (resultPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color.red : Color.green
    return UiPosition(id: position.objectID,
                      titleText: titleText,
                      typeText: typeText,
                      tradeResultText: resultText,
                      tradeResultTextColor: resultColor,
                      action: uiActionButton
    )
}

