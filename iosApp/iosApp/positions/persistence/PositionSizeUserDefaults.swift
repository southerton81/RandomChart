import Foundation

func savePositionSize(positionSizePct: Double) {
    UserDefaults.standard.set(positionSizePct, forKey: "positionSizePct")
}

func readPositionSize() -> Double {
    return (UserDefaults.standard.object(forKey: "positionSizePct") as? Double) ?? PositionSizeConstants.positionSizePctDefault
}

fileprivate enum PositionSizeConstants {
    static let positionSizeKey = "positionSizeKey"
    static let positionSizePctDefault: Double = 100
}
