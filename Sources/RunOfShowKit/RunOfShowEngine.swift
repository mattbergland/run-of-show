import Foundation

/// High-level entry point used by the app and tests. Wraps an `AIProvider` and
/// turns a single line of user text into a complete `RunOfShowPlan`.
public struct RunOfShowEngine: Sendable {
    private let provider: AIProvider

    public init(provider: AIProvider) {
        self.provider = provider
    }

    /// Generate a plan from the single free-text input.
    public func generatePlan(from input: String) async throws -> RunOfShowPlan {
        let request = PlanRequest(rawInput: input)
        return try await provider.generatePlan(for: request)
    }

    /// Generate a plan from an already-built request.
    public func generatePlan(for request: PlanRequest) async throws -> RunOfShowPlan {
        try await provider.generatePlan(for: request)
    }

    /// Build the engine the app should use: the real Claude provider when an API
    /// key is present, otherwise the offline `MockProvider`. The
    /// `forceMock` flag lets UI tests pin deterministic, offline output.
    public static func makeDefault(
        forceMock: Bool = false,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> RunOfShowEngine {
        if !forceMock, let claude = ClaudeProvider(environment: environment) {
            return RunOfShowEngine(provider: claude)
        }
        return RunOfShowEngine(provider: MockProvider())
    }
}
