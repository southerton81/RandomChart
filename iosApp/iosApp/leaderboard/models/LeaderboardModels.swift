import Foundation

struct UserModel: Hashable, Decodable {
    let userName: String
}

struct ScoreModel: Hashable, Identifiable, Decodable {
    let id: Int64 = autoincrement()
    let userName: String
    let userScore: Int64
    
    static func resetIndex() {
        inc = 0
    }
    
    static private func autoincrement() -> Int64 {
        inc += 1
        return inc
    }
    static private var inc: Int64 = 0
}

struct TokenModel: Decodable {
    let accessToken: String
}
