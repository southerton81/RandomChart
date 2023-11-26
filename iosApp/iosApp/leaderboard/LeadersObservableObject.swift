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
     
    
    private let c: CoreDataInventory
    
    init(_ c: CoreDataInventory) {
        self.c = c
    }
    
    func updateScores(_ currentPriceCents: Int64) {
        Task {
            do {
                let myScore = await calculateProfit(c, currentPriceCents)
              
                
                do {
                    try await postScore(score: myScore.floorToInt64())
                } catch {
                    // Empty
                }
                
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
    
    func getScores() async throws -> [ScoreModel] { 
        let (data, _) = try await URLSession.shared.data(from: Endpoint.getScores.url)
        ScoreModel.resetIndex()
        return try JSONDecoder().decode([ScoreModel].self, from: data)
    }
      
    func getUser() async throws -> Optional<UserModel> {
        guard let accessTokenData = loadFromKeychain(keyChainServiceName, keyChainAccountName), let accessToken = toUtf8String(accessTokenData) else {
            return Optional.none
        }
        
        do {
            let (data, _) = try await URLSession.shared.request(from: Endpoint.getUser.url, authorizationToken: accessToken)
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
        
        let (data, _) = try await URLSession.shared.request(from: Endpoint.postScore.url, httpMethod: "POST", body: [
            "score": score
        ], authorizationToken: accessToken)
    }
    
    func onUserJoin(_ username: String, _ currentPriceCents: Int64) {
        let lastScores = self.leaderboardUiModel.scores
        Task {
            do {
                await MainActor.run {
                    self.leaderboardUiModel = LeaderboardUiModel(scores: [], userScoreIndex: -1, showSignupPrompt: false, showProgress: true)
                }
                
                let myScore = await calculateProfit(c, currentPriceCents)
                 
                let (data, _) = try await URLSession.shared.request(from: Endpoint.postSignup.url, httpMethod: "POST", body: [
                    "username": username,
                    "password": UUID().uuidString,
                    "score": myScore.floorToInt64()
                ])
                
                let tokenModel = try JSONDecoder().decode(TokenModel.self, from: data)
                saveToKeychain(Data(tokenModel.accessToken.utf8), keyChainServiceName, keyChainAccountName)
                updateScores(currentPriceCents)
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
    
    func calculateProfit(_ c: CoreDataInventory, _ currentPriceCents: Int64) async -> NSDecimalNumber {
        await calculateTotalFunds(c, currentPriceCents).totalCap.subtracting(100_000)
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
