import Foundation

enum Endpoint {
    case postSignup
    case postScore
    case getScores
    case getUser
}

extension Endpoint {
    var url: URL {
        switch self {
        case .postSignup:
            return .makeForEndpoint("auth/signup")
        case .postScore:
            return .makeForEndpoint("scores/score")
        case .getScores:
            return .makeForEndpoint("scores/")
        case .getUser:
            return .makeForEndpoint("users/user")
        }
    }
}

private extension URL {
    static func makeForEndpoint(_ endpoint: String) -> URL {
        URL(string: "https://scoreboard-randomchart.ew.r.appspot.com/api/\(endpoint)")!
        //URL(string: "http://localhost:8080/api/\(endpoint)")!
    }
}

