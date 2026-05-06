import Foundation

final class NovaAIEngine {
    static let shared = NovaAIEngine()

    enum AIError: Error {
        case noApiKey
        case networkError
        case unauthorized
        case rateLimited
        case serverError(Int)
        case parseError
    }

    private var groqKey: String {
        let raw = SharedSettings.string(forKey: AppGroupKeys.groqApiKey) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentTask: URLSessionDataTask?

    func request(prompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        currentTask?.cancel()
        
        if groqKey.isEmpty {
            DispatchQueue.main.async { completion(.failure(.noApiKey)) }
            return
        }

        let endpoint = "https://api.groq.com/openai/v1/chat/completions"
        let body: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 500
        ]

        guard let url = URL(string: endpoint),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { completion(.failure(.parseError)) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(groqKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        currentTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error as NSError?, err.domain == NSURLErrorDomain && err.code == NSURLErrorCancelled {
                // Task was cancelled by a newer request, do not return failure
                return
            }
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(.failure(.networkError)) }
                return
            }

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200: break
                case 401:
                    DispatchQueue.main.async { completion(.failure(.unauthorized)) }
                    return
                case 429:
                    DispatchQueue.main.async { completion(.failure(.rateLimited)) }
                    return
                case 400...499, 500...599:
                    DispatchQueue.main.async { completion(.failure(.serverError(http.statusCode))) }
                    return
                default: break
                }
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let text = message["content"] as? String {
                let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                DispatchQueue.main.async { completion(.success(clean)) }
            } else {
                DispatchQueue.main.async { completion(.failure(.parseError)) }
            }
        }
        currentTask?.resume()
    }
}
