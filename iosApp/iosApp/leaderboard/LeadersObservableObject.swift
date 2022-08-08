import Foundation
import SwiftUI

class LeadersObservableObject: ObservableObject {
    @Published var leaderboardUiModel: LeaderboardUiModel = LeaderboardUiModel(scores: [],
                                                                               userScoreIndex: -1,
                                                                               showSignupPrompt: false, showProgress: true)
    @Published var errorState = ErrorState(title: nil)
    @Published var error: Swift.Error?
    
    private let keyChainServiceName = "access-token"
    private let keyChainAccountName = "charttycoon"
     
    private let scoresEndpoint = "http://localhost:8080/api/scores/"
    private let userEndpoint = "http://localhost:8080/api/users/user"
    private let signUpEndpoint = "http://localhost:8080/api/auth/signup"
    
    
    func fetchScores() async throws -> [ScoreModel] {
        let url = URL(string: scoresEndpoint)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ScoreModel].self, from: data)
    }
      
    func fetchUser() async throws -> Optional<UserModel> {
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
    
    func fetch() {
        self.leaderboardUiModel = LeaderboardUiModel(scores: leaderboardUiModel.scores,
                                                     userScoreIndex: leaderboardUiModel.userScoreIndex,
                                                     showSignupPrompt: false, showProgress: true)
        Task {
            do {
                async let scores = fetchScores()
                async let user = fetchUser()
                let leaderboardUiModel = try await buildUiLeaderboard(scores, user)
                await MainActor.run {
                    self.leaderboardUiModel = leaderboardUiModel
                }
            } catch {
                await MainActor.run {
                    self.errorState.title = "Could not connect to server"
                }
                
                try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                await MainActor.run {
                    self.leaderboardUiModel = LeaderboardUiModel(scores: [], userScoreIndex: -1, showSignupPrompt: false, showProgress: false)
                }
            }
        }
    }
    
    func onUserJoin(_ username: String) {
        let lastScores = self.leaderboardUiModel.scores
        Task {
            do {
                await MainActor.run {
                    self.leaderboardUiModel = LeaderboardUiModel(scores: [], userScoreIndex: -1, showSignupPrompt: false, showProgress: true)
                }
                
                let url = URL(string: signUpEndpoint)!
                let (data, _) = try await URLSession.shared.data(from: url, httpMethod: "POST", body: [
                    "username": username,
                    "password": UUID().uuidString,
                    "score": 250
                ])
                
                let tokenModel = try JSONDecoder().decode(TokenModel.self, from: data)
                let result = saveToKeychain(Data(tokenModel.accessToken.utf8), keyChainServiceName, keyChainAccountName)
                fetch()
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
    
    func buildUiLeaderboard(_ scores: [ScoreModel], _ user: Optional<UserModel>) -> LeaderboardUiModel {
        guard let userName = user?.userName else {
            return LeaderboardUiModel(scores: scores, userScoreIndex: -1, showSignupPrompt: true, showProgress: false)
        }
        
        let userScoreIndex = scores.firstIndex { scoreModel in
            scoreModel.userName == userName
        }
        
        return LeaderboardUiModel(scores: scores, userScoreIndex: userScoreIndex, showSignupPrompt: userScoreIndex == nil, showProgress: false)
    }
}

struct LeaderboardUiModel {
    let scores: [ScoreModel]
    let userScoreIndex: Int?
    let showSignupPrompt: Bool
    let showProgress: Bool
}

struct UserModel: Hashable, Decodable {
    let userName: String
}

struct ScoreModel: Hashable, Identifiable, Decodable {
    let id: Int64 = autoincrement()
    let userName: String
    let userScore: Int64
    
    static private func autoincrement() -> Int64 {
        inc += 1
        return inc
    }
    static private var inc: Int64 = 0
}

struct TokenModel: Decodable {
    let accessToken: String
}

struct ErrorState {
    var title: String?
}

class HttpError : Error {
    let errorCode: Int
    
    init(_ errorCode: Int) {
        self.errorCode = errorCode
    }
}
