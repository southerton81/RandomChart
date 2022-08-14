import Foundation
import SwiftUI

struct LeaderboardUiModel {
    let scores: [ScoreUiModel]
    let userScoreIndex: Int
    let showSignupPrompt: Bool
    let showProgress: Bool
}

struct ScoreUiModel: Hashable, Identifiable {
    let id: Int64
    let userName: String
    let userScore: Int64
    let backgroundColor: Color
}
