import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// `AIProvider` backed by the real Anthropic Messages API.
///
/// - Endpoint: `https://api.anthropic.com/v1/messages`
/// - Auth header: `x-api-key`
/// - Version header: `anthropic-version: 2023-06-01`
///
/// The API key is read from the environment (`ANTHROPIC_API_KEY`) by default and
/// is never hardcoded. The model defaults to a current Claude Sonnet model.
public struct ClaudeProvider: AIProvider {
    public struct Configuration: Sendable {
        public var apiKey: String
        public var model: String
        public var maxTokens: Int
        public var endpoint: URL

        public init(
            apiKey: String,
            model: String = ClaudeProvider.defaultModel,
            maxTokens: Int = ClaudeProvider.defaultMaxTokens,
            endpoint: URL = URL(string: "https://api.anthropic.com/v1/messages")!
        ) {
            self.apiKey = apiKey
            self.model = model
            self.maxTokens = maxTokens
            self.endpoint = endpoint
        }
    }

    /// Current Claude Sonnet model (verified against Anthropic's model docs).
    public static let defaultModel = "claude-sonnet-4-6"
    public static let apiKeyEnvVar = "ANTHROPIC_API_KEY"

    /// A full 8-section plan does not fit in 4096 output tokens — the response
    /// comes back truncated (`stop_reason == "max_tokens"`). 8192 leaves
    /// comfortable headroom for the complete document.
    public static let defaultMaxTokens = 8192

    /// A complete plan takes ~2 minutes to generate, well past `URLSession.shared`'s
    /// 60s default. This session allows up to 5 minutes per request.
    public static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        return URLSession(configuration: configuration)
    }()

    private let configuration: Configuration
    private let session: URLSession

    public init(configuration: Configuration, session: URLSession = ClaudeProvider.defaultSession) {
        self.configuration = configuration
        self.session = session
    }

    /// Convenience initializer that reads the API key from the environment.
    /// Returns `nil` when the key is absent so callers can fall back to the
    /// `MockProvider`.
    public init?(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        model: String = ClaudeProvider.defaultModel,
        session: URLSession = ClaudeProvider.defaultSession
    ) {
        guard let key = environment[ClaudeProvider.apiKeyEnvVar], !key.isEmpty else {
            return nil
        }
        self.init(configuration: Configuration(apiKey: key, model: model), session: session)
    }

    public func generatePlan(for request: PlanRequest) async throws -> RunOfShowPlan {
        let body = MessagesRequest(
            model: configuration.model,
            maxTokens: configuration.maxTokens,
            system: PromptBuilder.systemPrompt,
            messages: [.init(role: "user", content: PromptBuilder.userPrompt(for: request))]
        )

        var urlRequest = URLRequest(url: configuration.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await Self.perform(urlRequest, session: session)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw AIProviderError.httpError(status: http.statusCode, body: bodyText)
        }

        return try Self.decodePlan(fromResponseData: data)
    }

    /// Decodes a `RunOfShowPlan` from a raw Anthropic Messages response body.
    ///
    /// Pure and network-free so the truncation/parse paths can be unit-tested on
    /// Linux. Surfaces a clear error when the model ran out of output tokens
    /// (`stop_reason == "max_tokens"`) rather than a confusing JSON parse failure.
    static func decodePlan(fromResponseData data: Data) throws -> RunOfShowPlan {
        let decoded: MessagesResponse
        do {
            decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
        } catch {
            throw AIProviderError.parsingFailed("Unexpected Anthropic response envelope: \(error)")
        }

        if decoded.stopReason == "max_tokens" {
            throw AIProviderError.parsingFailed(
                "The model's response was cut off before the full plan was returned "
                + "(stop_reason=max_tokens). Increase Configuration.maxTokens and try again."
            )
        }

        let text = decoded.content.compactMap { $0.text }.joined()
        guard !text.isEmpty else {
            throw AIProviderError.parsingFailed("Anthropic response contained no text content.")
        }
        return try JSONExtractor.decodePlan(from: text)
    }

    // MARK: - URLSession bridging
    //
    // Use a continuation around the completion-handler API so the provider
    // works identically on Linux (where the async `data(for:)` overload is not
    // always available) and Apple platforms.
    private static func perform(_ request: URLRequest, session: URLSession) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: AIProviderError.transport(error.localizedDescription))
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: AIProviderError.transport("Empty response from server."))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}

// MARK: - Anthropic wire models

extension ClaudeProvider {
    struct MessagesRequest: Encodable {
        let model: String
        let maxTokens: Int
        let system: String
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case system
            case messages
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct MessagesResponse: Decodable {
        let content: [ContentBlock]
        let stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }
}
