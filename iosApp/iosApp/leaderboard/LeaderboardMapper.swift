import Foundation
import SwiftUI

func mapScoreModelToUi(scoreModel: ScoreModel, isMyScore: Bool) -> ScoreUiModel {
    var backgroundColor = scoreModel.id > 0 && scoreModel.id % 2 == 0 ? Color(UIColor.systemGray) : Color(UIColor.systemGray5)
    if isMyScore {
        backgroundColor = Color(UIColor.systemIndigo)
    }
    return ScoreUiModel(id: scoreModel.id, userName: scoreModel.userName, userScore: scoreModel.userScore,
                        backgroundColor: backgroundColor)
}
