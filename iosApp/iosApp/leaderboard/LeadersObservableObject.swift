import Foundation
import SwiftUI
import CoreData

class LeadersObservableObject: ObservableObject {
    @Published var leaderboardUiModel: LeaderboardUiModel = LeaderboardUiModel(scores: [],
                                                                               userScoreIndex: -1,
                                                                               showSignupPrompt: false, showProgress: true)
    @Published var errorState = ErrorState(title: nil)
    @Published var error: Swift.Error?
    
    private let keyChainServiceName = "access-token"
    private let keyChainAccountName = "charttycoon"
    
    private let scoreEndpoint = "http://localhost:8080/api/scores/score"
    private let scoresEndpoint = "http://localhost:8080/api/scores/"
    private let userEndpoint = "http://localhost:8080/api/users/user"
    private let signUpEndpoint = "http://localhost:8080/api/auth/signup"
    
    
    func getScores() async throws -> [ScoreModel] {
        let url = URL(string: scoresEndpoint)!
        let (data, _) = try await URLSession.shared.data(from: url)
        ScoreModel.resetIndex()
        return try JSONDecoder().decode([ScoreModel].self, from: data)
    }
      
    func getUser() async throws -> Optional<UserModel> {
        guard let accessTokenData = loadFromKeychain(keyChainServiceName, keyChainAccountName), let accessToken = toUtf8String(accessTokenData) else {
            return Optional.none
        }
        
        do {
            let url = URL(string: userEndpoint)!
            let (data, _) = try await URLSession.shared.data(from: url, authorizationToken: accessToken)
            return try Optional.some(JSONDecoder().decode(UserModel.self, from: data))
        } catch {
            if let httpError = error as? HttpError {
                if httpError.errorCode == 401 {
                    self.errorState.title = "Cannot login with an existing name"
                    return Optional.none
                }
            }
            throw error
        }
    }
    
    func postScore(score: Int64) async throws {
        guard let accessTokenData = loadFromKeychain(keyChainServiceName, keyChainAccountName), let accessToken = toUtf8String(accessTokenData) else {
            return
        }
        
        let url = URL(string: scoreEndpoint)!
        let (data, _) = try await URLSession.shared.data(from: url, httpMethod: "POST", body: [
            "score": score
        ], authorizationToken: accessToken)
    }
    
    func updateScores(_ c: PersistentContainer) {
        self.leaderboardUiModel = LeaderboardUiModel(scores: leaderboardUiModel.scores,
                                                     userScoreIndex: leaderboardUiModel.userScoreIndex,
                                                     showSignupPrompt: false, showProgress: true)
        Task {
            do {
                let myScore = await calculateProfit(c)
                try await postScore(score: myScore.floorToInt64())
                
                async let user = getUser()
                async let scores = getScores()
                let leaderboardUiModel = try await buildUiLeaderboard(scores, user)
                
                await MainActor.run {
                    self.leaderboardUiModel = leaderboardUiModel
                }
            } catch {
                await MainActor.run {
                    self.errorState.title = "Could not connect to server"
                }
                
                try await Task.sleep(nanoseconds: 1 * 1_000_000_000 /* 1 second till progress bar would be hidden */ )
                
                await MainActor.run {
                    self.leaderboardUiModel = LeaderboardUiModel(scores: [], userScoreIndex: -1, showSignupPrompt: false, showProgress: false)
                }
            }
        }
    }
    
    func onUserJoin(_ c: PersistentContainer, _ username: String) {
        let lastScores = self.leaderboardUiModel.scores
        Task {
            do {
                await MainActor.run {
                    self.leaderboardUiModel = LeaderboardUiModel(scores: [], userScoreIndex: -1, showSignupPrompt: false, showProgress: true)
                }
                
                let myScore = await calculateProfit(c)
                
                let url = URL(string: signUpEndpoint)!
                let (data, _) = try await URLSession.shared.data(from: url, httpMethod: "POST", body: [
                    "username": username,
                    "password": UUID().uuidString,
                    "score": myScore.floorToInt64()
                ])
                
                let tokenModel = try JSONDecoder().decode(TokenModel.self, from: data)
                saveToKeychain(Data(tokenModel.accessToken.utf8), keyChainServiceName, keyChainAccountName)
                updateScores(c)
            } catch {
                await MainActor.run {
                    self.leaderboardUiModel = LeaderboardUiModel(scores: lastScores, userScoreIndex: -1, showSignupPrompt: true, showProgress: false)

                    if let httpError = error as? HttpError {
                        if httpError.errorCode == 409 {
                            self.errorState.title = "Nickname already taken"
                            return
                        }
                    }
                    
                    self.errorState.title = "Could not join"
                }
            }
        }
    }
    
    func calculateProfit(_ c: PersistentContainer) async -> NSDecimalNumber {
        return await c.sharedBackgroundContext().perform(schedule: NSManagedObjectContext.ScheduledTaskType.immediate) { () -> NSDecimalNumber in
            let fetchRequest = NSFetchRequest<Position>(entityName: "Position")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startPeriod", ascending: true)]
            
            if let positions = try? fetchRequest.execute() {
                if (positions.isEmpty) {
                    return NSDecimalNumber.zero
                }
                
                let closedPositionsValue = positions
                    .filter({ p in p.closed == true })
                    .map({ p in
                        calculateClosedPostionValue(p)
                    }).reduce(NSDecimalNumber.zero) { result, next in
                        result.adding(next)
                    }
                
                let openPositionsUnrealizedValue = positions
                    .filter({ p in p.closed == false })
                    .map({ p in
                        calculateOpenPositionStartValue(p)
                    }).reduce(NSDecimalNumber.zero) { result, next in
                        result.adding(next)
                    }
                
                let positionsCost = positions
                    .map({ p in
                        p.quantity?.multiplying(by: p.startPrice ?? 0) ?? 0
                    }).reduce(NSDecimalNumber.zero) { result, next in
                        result.adding(next)
                    }
                
                let totalUnrealizedCap = closedPositionsValue.subtracting(positionsCost).adding(openPositionsUnrealizedValue)
                return totalUnrealizedCap.subtracting(100_000)
            }
            
            return NSDecimalNumber.zero
        }
    }
    
    fileprivate func buildUiLeaderboard(_ scores: [ScoreModel], _ user: Optional<UserModel>) -> LeaderboardUiModel {
        guard let userName = user?.userName else {
            let scoreUiModels = scores.map({scoreModel in
                mapScoreModelToUi(scoreModel: scoreModel, isMyScore: false)
            })
            return LeaderboardUiModel(scores: scoreUiModels, userScoreIndex: -1, showSignupPrompt: true, showProgress: false)
        }
        
        var userScoreIndex = scores.firstIndex { scoreModel in
            scoreModel.userName == userName
        } ?? -1
        
        if (userScoreIndex > 0) {
            userScoreIndex = min(userScoreIndex + 5, scores.count)
        }
        
        let scoreUiModels = scores.map({scoreModel in
            mapScoreModelToUi(scoreModel: scoreModel, isMyScore: scoreModel.userName == userName)
        })
        
        return LeaderboardUiModel(scores: scoreUiModels, userScoreIndex: userScoreIndex, showSignupPrompt: userScoreIndex == nil, showProgress: false)
    }
}

struct ErrorState {
    var title: String?
}
