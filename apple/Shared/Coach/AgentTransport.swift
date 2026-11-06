import Foundation

/// JSON objects preserve the full assistant message, including provider reasoning fields, on replay.
@MainActor
protocol AgentTransport {
    func complete(messages: [[String: Any]], tools: [[String: Any]]) async throws -> [String: Any]
}

enum AgentRequestDiagnostics {
    static func log(engine: String, method: String, url: URL, messages: Int? = nil, tools: Int? = nil) {
        var detail = "[AgentRequest] engine=\(engine) method=\(method) url=\(url.absoluteString)"
        if let messages { detail += " messages=\(messages)" }
        if let tools { detail += " tools=\(tools)" }
        print(detail)
    }
}

enum AgentError: LocalizedError {
    case invalidResponse, invalidEndpoint, http(Int), roundLimit, signInRequired
    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The racket agent received an incomplete response."
        case .invalidEndpoint: "Enter a valid Lemonade server address using HTTP or HTTPS."
        case .http(let code): "The agent request failed (HTTP \(code))."
        case .roundLimit: "The racket agent reached its tool limit."
        case .signInRequired: "Sign in is required for the optional cloud proxy."
        }
    }
}

/// OpenAI-compatible transport for a Lemonade server running on the player's network.
@MainActor
struct LemonadeTransport: AgentTransport {
    static let defaultBaseAddress = "http://localhost:8000/api/v1"
    let baseAddress: String
    var model: String
    var session: URLSession = .shared
    var timeout: TimeInterval = 45

    init(baseAddress: String = LemonadeTransport.defaultBaseAddress, model: String = "",
         session: URLSession = .shared, timeout: TimeInterval = 45) {
        self.baseAddress = baseAddress.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        self.model = model
        self.session = session
        self.timeout = timeout
    }

    func availableModels() async throws -> [String] {
        let url = try endpoint("models")
        AgentRequestDiagnostics.log(engine: "Lemonade", method: "GET", url: url)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AgentError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw AgentError.http(http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["data"] as? [[String: Any]] else { throw AgentError.invalidResponse }
        return rows.compactMap { $0["id"] as? String }
    }

    func testConnection() async throws -> (models: [String], latencyMilliseconds: Int) {
        let start = ContinuousClock.now
        let models = try await availableModels()
        let elapsed = start.duration(to: .now)
        let milliseconds = Int((Double(elapsed.components.seconds) * 1_000
            + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000).rounded())
        return (models, milliseconds)
    }

    func complete(messages: [[String: Any]], tools: [[String: Any]]) async throws -> [String: Any] {
        guard !model.isEmpty else { throw AgentError.invalidResponse }
        let url = try endpoint("chat/completions")
        AgentRequestDiagnostics.log(engine: "Lemonade", method: "POST", url: url,
                                    messages: messages.count, tools: tools.count)
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["model": model, "messages": messages,
                                   "max_completion_tokens": 4096, "enable_thinking": false]
        if !tools.isEmpty { body["tools"] = tools; body["tool_choice"] = "auto" }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AgentError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw AgentError.http(http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]], let choice = choices.first,
              let reason = choice["finish_reason"] as? String, ["stop", "tool_calls"].contains(reason),
              let message = choice["message"] as? [String: Any], message["role"] as? String == "assistant"
        else { throw AgentError.invalidResponse }
        return message
    }

    private func endpoint(_ path: String) throws -> URL {
        guard let url = URL(string: "\(baseAddress)/\(path)"),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
            throw AgentError.invalidEndpoint
        }
        return url
    }
}

@MainActor
struct CloudProxyTransport: AgentTransport {
    /// Optional legacy proxy transport. The default build uses Lemonade and does not call this transport.
    let endpoint: URL
    let publishableKey: String
    let accessToken: String
    var model = ""
    var session: URLSession = .shared

    func complete(messages: [[String: Any]], tools: [[String: Any]]) async throws -> [String: Any] {
        guard !accessToken.isEmpty else { throw AgentError.signInRequired }
        AgentRequestDiagnostics.log(engine: "Optional cloud proxy", method: "POST", url: endpoint,
                                    messages: messages.count, tools: tools.count)
        var request = URLRequest(url: endpoint, timeoutInterval: 45)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["model": model, "messages": messages,
                                   "max_completion_tokens": 4096]
        if !tools.isEmpty { body["tools"] = tools; body["tool_choice"] = "auto" }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        // No automatic retries: rate limits and network errors immediately use the local fallback.
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AgentError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw AgentError.http(http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]], let choice = choices.first,
              let reason = choice["finish_reason"] as? String, ["stop", "tool_calls"].contains(reason),
              let message = choice["message"] as? [String: Any], message["role"] as? String == "assistant"
        else { throw AgentError.invalidResponse }
        return message
    }
}
