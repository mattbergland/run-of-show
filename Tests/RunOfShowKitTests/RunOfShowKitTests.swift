import XCTest
@testable import RunOfShowKit

final class RunOfShowKitTests: XCTestCase {

    private let exampleInput = "AI founder dinner for 30 people in SF. Intimate, premium, not too corporate. Need it in 3 weeks."

    // MARK: - Engine produces every required section

    func testEngineProducesEveryRequiredSection() async throws {
        let engine = RunOfShowEngine(provider: MockProvider())
        let plan = try await engine.generatePlan(from: exampleInput)

        XCTAssertFalse(plan.eventTitle.isEmpty, "Event title should be populated")
        XCTAssertFalse(plan.summary.isEmpty, "Summary should be populated")

        // Each of the eight required output sections must be present and non-empty.
        XCTAssertFalse(plan.runOfShow.isEmpty, "Run-of-show timeline missing")
        XCTAssertFalse(plan.venueRequirements.isEmpty, "Venue requirements missing")
        XCTAssertFalse(plan.budget.lineItems.isEmpty, "Budget line items missing")
        XCTAssertFalse(plan.inviteCopy.subjectLine.isEmpty, "Invite subject missing")
        XCTAssertFalse(plan.inviteCopy.body.isEmpty, "Invite body missing")
        XCTAssertFalse(plan.staffingPlan.isEmpty, "Staffing plan missing")
        XCTAssertFalse(plan.vendorChecklist.isEmpty, "Vendor checklist missing")
        XCTAssertFalse(plan.dayOfTimeline.isEmpty, "Day-of timeline missing")
        XCTAssertFalse(plan.followUpPlan.isEmpty, "Follow-up plan missing")

        XCTAssertTrue(plan.isComplete, "Plan should report itself as complete")
    }

    func testRequiredSectionTitlesCountMatchesSpec() {
        // The spec lists eight magical output sections.
        XCTAssertEqual(RunOfShowPlan.requiredSectionTitles.count, 8)
    }

    // MARK: - Mock provider is deterministic and reflects input

    func testMockProviderIsDeterministic() async throws {
        let provider = MockProvider()
        let request = PlanRequest(rawInput: exampleInput)
        let first = try await provider.generatePlan(for: request)
        let second = try await provider.generatePlan(for: request)
        XCTAssertEqual(first, second, "MockProvider must be fully deterministic")
    }

    func testMockProviderReflectsParsedAttendeeCountAndLocation() async throws {
        let plan = try await MockProvider().generatePlan(for: PlanRequest(rawInput: exampleInput))
        XCTAssertTrue(plan.summary.contains("30"), "Attendee count should flow into the summary")
        XCTAssertTrue(plan.eventTitle.contains("SF"), "Location should flow into the title")
        // Budget should scale with the parsed headcount (30 * $95 food line).
        let foodLine = plan.budget.lineItems.first { $0.item.contains("Food") }
        XCTAssertEqual(foodLine?.estimatedCost, 30 * 95)
    }

    func testBudgetTotalEqualsSumOfLineItems() async throws {
        let plan = try await MockProvider().generatePlan(for: PlanRequest(rawInput: exampleInput))
        XCTAssertEqual(plan.budget.total, plan.budget.computedTotal, accuracy: 0.001)
        XCTAssertGreaterThan(plan.budget.total, 0)
    }

    // MARK: - Codable round-trips

    func testPlanCodableRoundTrip() throws {
        let original = MockProvider.plan(for: PlanRequest(rawInput: exampleInput))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RunOfShowPlan.self, from: data)
        XCTAssertEqual(original, decoded, "RunOfShowPlan must round-trip through Codable")
    }

    func testAllSectionModelsRoundTrip() throws {
        try assertRoundTrip(RunOfShowSegment(time: "6:30 PM", title: "Doors", details: "Welcome drinks", durationMinutes: 30))
        try assertRoundTrip(VenueRequirement(category: "Capacity", requirement: "Seats 30"))
        try assertRoundTrip(BudgetLineItem(item: "Food", estimatedCost: 2850, notes: "Family-style"))
        try assertRoundTrip(Budget(currency: "USD", lineItems: [BudgetLineItem(item: "Food", estimatedCost: 100)]))
        try assertRoundTrip(InviteCopy(subjectLine: "You're invited", body: "Join us"))
        try assertRoundTrip(StaffRole(role: "Host", responsibilities: "MC", count: 1))
        try assertRoundTrip(VendorItem(vendor: "Florist", whatToConfirm: "Delivery time"))
        try assertRoundTrip(TimelineEntry(time: "3 PM", activity: "Setup", owner: "Lead"))
        try assertRoundTrip(FollowUpStep(timing: "24h", action: "Send recap"))
        try assertRoundTrip(ParsedInput(rawText: "x", eventDescription: "x"))
        try assertRoundTrip(PlanRequest(rawInput: exampleInput))
    }

    private func assertRoundTrip<T: Codable & Equatable>(_ value: T, file: StaticString = #file, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(value, decoded, file: file, line: line)
    }

    // MARK: - Input parsing

    func testParserExtractsAttendeeCountLocationTimeframe() {
        let parsed = InputParser.parse(exampleInput)
        XCTAssertEqual(parsed.attendeeCount, 30)
        XCTAssertEqual(parsed.location, "SF")
        XCTAssertEqual(parsed.timeframe?.lowercased(), "in 3 weeks")
        XCTAssertNil(parsed.lumaURL)
        XCTAssertFalse(parsed.isTooShort)
    }

    func testParserDetectsLumaLink() {
        let parsed = InputParser.parse("Check out my event https://lu.ma/abc123 please")
        XCTAssertEqual(parsed.lumaURL?.absoluteString, "https://lu.ma/abc123")
        XCTAssertFalse(parsed.eventDescription.contains("https://lu.ma/abc123"),
                       "URL should be stripped from the description")
    }

    func testParserHandlesNonLumaURL() {
        let parsed = InputParser.parse("Event details at https://example.com/event")
        XCTAssertNil(parsed.lumaURL, "Only Luma links should be captured as lumaURL")
    }

    // MARK: - Prompt construction

    func testPromptIncludesUserInputAndAllSections() {
        let request = PlanRequest(rawInput: exampleInput)
        let prompt = PromptBuilder.userPrompt(for: request)

        XCTAssertTrue(prompt.contains(exampleInput), "Prompt must include the user's raw input")
        for title in RunOfShowPlan.requiredSectionTitles {
            XCTAssertTrue(prompt.contains(title), "Prompt must mention required section: \(title)")
        }
        // Parsed hints should be surfaced to the model.
        XCTAssertTrue(prompt.contains("30"), "Prompt should include parsed attendee count")
        XCTAssertTrue(prompt.contains("SF"), "Prompt should include parsed location")
    }

    func testSystemPromptDemandsJSON() {
        XCTAssertTrue(PromptBuilder.systemPrompt.lowercased().contains("json"))
    }

    func testSchemaDescriptionCoversEveryJSONKey() {
        for key in PromptBuilder.requiredSectionKeys {
            XCTAssertTrue(PromptBuilder.jsonSchemaDescription.contains(key),
                          "Schema description must document key: \(key)")
        }
    }

    // MARK: - Edge cases

    func testEmptyInputDoesNotCrashAndStillProducesCompletePlan() async throws {
        let plan = try await RunOfShowEngine(provider: MockProvider()).generatePlan(from: "")
        XCTAssertTrue(plan.isComplete, "Even empty input should yield a complete fallback plan")
    }

    func testVeryShortInputIsHandled() async throws {
        let parsedShort = InputParser.parse("hi")
        XCTAssertTrue(parsedShort.isTooShort)

        let plan = try await RunOfShowEngine(provider: MockProvider()).generatePlan(from: "hi")
        XCTAssertTrue(plan.isComplete, "Short input should still produce a complete plan via defaults")
    }

    func testWhitespaceOnlyInput() {
        let parsed = InputParser.parse("    \n  ")
        XCTAssertTrue(parsed.isTooShort)
        XCTAssertNil(parsed.attendeeCount)
    }

    // MARK: - JSON extraction (ClaudeProvider parsing path)

    func testJSONExtractorParsesPlainJSON() throws {
        let plan = MockProvider.plan(for: PlanRequest(rawInput: exampleInput))
        let json = String(data: try JSONEncoder().encode(plan), encoding: .utf8)!
        let decoded = try JSONExtractor.decodePlan(from: json)
        XCTAssertEqual(decoded, plan)
    }

    func testJSONExtractorStripsMarkdownFences() throws {
        let plan = MockProvider.plan(for: PlanRequest(rawInput: exampleInput))
        let json = String(data: try JSONEncoder().encode(plan), encoding: .utf8)!
        let fenced = "Here is your plan:\n```json\n\(json)\n```\nHope that helps!"
        let decoded = try JSONExtractor.decodePlan(from: fenced)
        XCTAssertEqual(decoded, plan)
    }

    func testJSONExtractorHandlesSurroundingProse() throws {
        let plan = MockProvider.plan(for: PlanRequest(rawInput: exampleInput))
        let json = String(data: try JSONEncoder().encode(plan), encoding: .utf8)!
        let messy = "Sure! \(json) Let me know if you want changes."
        let decoded = try JSONExtractor.decodePlan(from: messy)
        XCTAssertEqual(decoded, plan)
    }

    func testJSONExtractorThrowsOnGarbage() {
        XCTAssertThrowsError(try JSONExtractor.decodePlan(from: "not json at all")) { error in
            guard case AIProviderError.parsingFailed = error else {
                return XCTFail("Expected parsingFailed, got \(error)")
            }
        }
    }

    // MARK: - Provider selection

    func testMakeDefaultUsesMockWhenForced() {
        let engine = RunOfShowEngine.makeDefault(forceMock: true, environment: ["ANTHROPIC_API_KEY": "sk-test"])
        // forceMock should win even when a key is present; verify by exercising it offline.
        let expectation = expectation(description: "offline plan")
        Task {
            let plan = try await engine.generatePlan(from: exampleInput)
            XCTAssertTrue(plan.isComplete)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testClaudeProviderInitFailsWithoutKey() {
        XCTAssertNil(ClaudeProvider(environment: [:]), "Should return nil when no API key present")
        XCTAssertNotNil(ClaudeProvider(environment: ["ANTHROPIC_API_KEY": "sk-test"]))
    }

    func testClaudeProviderUsesCurrentModel() {
        XCTAssertEqual(ClaudeProvider.defaultModel, "claude-sonnet-4-6")
    }

    func testClaudeDefaultsLeaveHeadroomForFullPlan() {
        // 4096 truncates the 8-section plan; the default must leave headroom.
        XCTAssertEqual(ClaudeProvider.defaultMaxTokens, 8192)
        XCTAssertEqual(ClaudeProvider.Configuration(apiKey: "k").maxTokens, 8192)
    }

    func testClaudeDefaultSessionHasGenerousTimeouts() {
        // A full plan takes ~2 min; the 60s URLSession.shared default times out.
        let config = ClaudeProvider.defaultSession.configuration
        XCTAssertGreaterThanOrEqual(config.timeoutIntervalForRequest, 180)
        XCTAssertGreaterThanOrEqual(config.timeoutIntervalForResource, 180)
    }

    func testClaudeDecodeTruncatedResponseThrowsClearError() throws {
        let envelope: [String: Any] = [
            "content": [["type": "text", "text": "{\"eventTitle\":\"AI Founder Dinner"]],
            "stop_reason": "max_tokens"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        XCTAssertThrowsError(try ClaudeProvider.decodePlan(fromResponseData: data)) { error in
            guard case let AIProviderError.parsingFailed(message) = error else {
                return XCTFail("Expected parsingFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("max_tokens"), "Error should explain truncation: \(message)")
        }
    }

    func testClaudeDecodeFullPlanResponseSucceeds() throws {
        let plan = MockProvider.plan(for: PlanRequest(rawInput: "AI founder dinner for 30 people in SF."))
        let planText = String(data: try JSONEncoder().encode(plan), encoding: .utf8)!
        let envelope: [String: Any] = [
            "content": [["type": "text", "text": planText]],
            "stop_reason": "end_turn"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        let decoded = try ClaudeProvider.decodePlan(fromResponseData: data)
        XCTAssertTrue(decoded.isComplete, "Decoded plan should contain every section")
        XCTAssertEqual(decoded.eventTitle, plan.eventTitle)
    }
}
