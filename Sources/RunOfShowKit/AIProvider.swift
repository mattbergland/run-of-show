import Foundation

/// A request to generate a complete event operating plan.
public struct PlanRequest: Codable, Equatable, Sendable {
    /// The exact text the user typed into the single input field.
    public var rawInput: String
    /// Structured interpretation of `rawInput`.
    public var parsed: ParsedInput

    public init(rawInput: String) {
        self.rawInput = rawInput
        self.parsed = InputParser.parse(rawInput)
    }

    public init(rawInput: String, parsed: ParsedInput) {
        self.rawInput = rawInput
        self.parsed = parsed
    }
}

/// Errors that can surface while generating a plan.
public enum AIProviderError: Error, Equatable, Sendable {
    /// No API key was available in the environment / Info.plist.
    case missingAPIKey
    /// The HTTP request failed with a non-2xx status code.
    case httpError(status: Int, body: String)
    /// The provider returned a payload that could not be parsed into a plan.
    case parsingFailed(String)
    /// The network layer produced an error.
    case transport(String)
}

/// Abstraction over anything that can turn a `PlanRequest` into a
/// `RunOfShowPlan`. Implemented by `MockProvider` (offline, deterministic) and
/// `ClaudeProvider` (real Anthropic Messages API).
public protocol AIProvider: Sendable {
    func generatePlan(for request: PlanRequest) async throws -> RunOfShowPlan
}
