import Foundation
import SwiftUI
import RunOfShowKit

/// Drives the single screen flow: takes the user's one-line input, asks the
/// engine for a plan, and exposes a simple state machine the views render.
@MainActor
final class PlanViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(RunOfShowPlan)
        case failed(String)
    }

    @Published var inputText: String
    @Published private(set) var state: State = .idle

    /// The example used for the empty-state hint and UI-test prefill.
    static let exampleInput = "AI founder dinner for 30 people in SF. Intimate, premium, not too corporate. Need it in 3 weeks."

    private let engine: RunOfShowEngine

    init(engine: RunOfShowEngine? = nil, environment: [String: String] = ProcessInfo.processInfo.environment) {
        let arguments = ProcessInfo.processInfo.arguments
        // Deterministic, offline mode for UI tests: force the MockProvider and
        // prefill the example so the test can reach a populated results screen.
        let forceMock = arguments.contains("-UITEST_MOCK") || arguments.contains("UITEST_MOCK")
        self.engine = engine ?? RunOfShowEngine.makeDefault(forceMock: forceMock, environment: environment)
        self.inputText = forceMock ? Self.exampleInput : ""
    }

    var isUsingMock: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITEST_MOCK")
    }

    func useExample() {
        inputText = Self.exampleInput
    }

    func generate() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        state = .loading
        Task {
            do {
                let plan = try await engine.generatePlan(from: trimmed)
                self.state = .loaded(plan)
            } catch {
                self.state = .failed(Self.message(for: error))
            }
        }
    }

    func reset() {
        state = .idle
    }

    private static func message(for error: Error) -> String {
        switch error {
        case AIProviderError.missingAPIKey:
            return "No API key found. Set ANTHROPIC_API_KEY to generate live plans, or run offline with the bundled example."
        case AIProviderError.httpError(let status, _):
            return "The AI service returned an error (HTTP \(status)). Please try again."
        case AIProviderError.parsingFailed:
            return "We couldn't read the plan that came back. Please try again."
        case AIProviderError.transport(let detail):
            return "Network problem: \(detail)"
        default:
            return "Something went wrong. Please try again."
        }
    }
}
