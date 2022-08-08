import Foundation
import CoreData
import SwiftUI

func mapToUiPosition(_ position: Position, _ lastPrice: Int64) -> UiPosition {
    let titleText = position.closed ? decimalToString(position.startPrice ?? NSDecimalNumber.zero) + " / " + decimalToString(position.endPrice ?? NSDecimalNumber.zero) : decimalToString(position.startPrice ?? NSDecimalNumber.zero)
    let typeText = position.long ? "Long" : "Short"
    let uiActionButton = position.closed ? nil : UiActionButton(caption: "Close", color: Color.blue)
    
    let lastPositionPrice = position.closed ? position.endPrice! : NSDecimalNumber(decimal: Decimal(lastPrice) / Decimal(100))
    let resultPct = getPercentDiff(value1: position.startPrice ?? NSDecimalNumber.zero, value2: lastPositionPrice, negative: !position.long)
    
    let resultText = decimalToString(resultPct, 2, showSign: true) + "%"
    let resultColor = (resultPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color.red : Color.green
    return UiPosition(id: position.id,
                      titleText: titleText,
                      typeText: typeText,
                      tradeResultText: resultText,
                      tradeResultTextColor: resultColor,
                      action: uiActionButton,
                      corePosition: position
    )
}

