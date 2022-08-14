import Foundation
import SwiftUI

func mapScoreModelToUi(scoreModel: ScoreModel, isMyScore: Bool) -> ScoreUiModel {
    var backgroundColor = scoreModel.id % 2 == 0 ? Color(UIColor.secondarySystemBackground) : Color(UIColor.tertiarySystemBackground)
    if isMyScore {
        backgroundColor = Color.yellow
    }
    
    return ScoreUiModel(id: scoreModel.id, userName: scoreModel.userName, userScore: scoreModel.userScore,
                        backgroundColor: backgroundColor)
}
