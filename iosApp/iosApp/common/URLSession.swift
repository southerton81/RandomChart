import Foundation

@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    func data(from url: URL, httpMethod: String = "GET", body: [String: Any] = [:],
              authorizationToken: String? = nil) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            
            var request = URLRequest(url: url)
            request.httpMethod = httpMethod
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = authorizationToken {
                request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
            }
            
            if (!body.isEmpty) {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                } catch let error {
                    print(error.localizedDescription)
                    return
                }
            }
            
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if (httpResponse.statusCode >= 400) {
                        return continuation.resume(throwing: HttpError(httpResponse.statusCode))
                    }
                }
                
                continuation.resume(returning: (data, response))
            }
            
            task.resume()
        }
    }
}

class HttpError : Error {
    let errorCode: Int
    
    init(_ errorCode: Int) {
        self.errorCode = errorCode
    }
}
