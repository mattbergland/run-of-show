import Foundation

/// Builds the system + user prompts sent to the language model and documents
/// the exact JSON shape the model must return. Kept separate from the provider
/// so prompt construction can be unit-tested without any network access.
public enum PromptBuilder {
    /// Machine-readable keys for every required output section. These are the
    /// JSON keys of `RunOfShowPlan` and are embedded into the prompt so the
    /// model returns a payload we can decode directly.
    public static let requiredSectionKeys: [String] = [
        "runOfShow",
        "venueRequirements",
        "budget",
        "inviteCopy",
        "staffingPlan",
        "vendorChecklist",
        "dayOfTimeline",
        "followUpPlan"
    ]

    /// System prompt establishing the assistant's role and output discipline.
    public static let systemPrompt: String = """
    You are Run of Show, an expert event operations producer. You turn a single \
    sentence describing an event into a complete, realistic, day-of operating plan \
    that a field marketer or founder could execute with confidence.

    You MUST respond with a single valid JSON object and nothing else — no prose, \
    no markdown fences. Every field is required and must be richly filled in with \
    specific, realistic content tailored to the user's event. Estimate sensible \
    numbers when the user does not provide them.
    """

    /// The JSON schema (as documentation embedded in the prompt) describing the
    /// expected response shape.
    public static let jsonSchemaDescription: String = """
    Return JSON with exactly this shape:
    {
      "eventTitle": String,
      "summary": String,
      "runOfShow": [ { "time": String, "title": String, "details": String, "durationMinutes": Int? } ],
      "venueRequirements": [ { "category": String, "requirement": String } ],
      "budget": {
        "currency": String,
        "lineItems": [ { "item": String, "estimatedCost": Number, "notes": String? } ],
        "total": Number
      },
      "inviteCopy": { "subjectLine": String, "body": String },
      "staffingPlan": [ { "role": String, "responsibilities": String, "count": Int? } ],
      "vendorChecklist": [ { "vendor": String, "whatToConfirm": String } ],
      "dayOfTimeline": [ { "time": String, "activity": String, "owner": String? } ],
      "followUpPlan": [ { "timing": String, "action": String } ]
    }
    """

    /// Build the user-facing prompt for a given request. Includes the user's raw
    /// input, any structured hints we parsed, the required sections, and the
    /// JSON schema.
    public static func userPrompt(for request: PlanRequest) -> String {
        var lines: [String] = []
        lines.append("Create a complete event operating plan for the following event idea:")
        lines.append("")
        lines.append("\"\"\"")
        lines.append(request.rawInput.isEmpty ? "(no description provided — design a sensible default event)" : request.rawInput)
        lines.append("\"\"\"")
        lines.append("")

        let parsed = request.parsed
        var hints: [String] = []
        if let url = parsed.lumaURL { hints.append("- Luma event link: \(url.absoluteString)") }
        if let count = parsed.attendeeCount { hints.append("- Approximate attendees: \(count)") }
        if let location = parsed.location { hints.append("- Location: \(location)") }
        if let timeframe = parsed.timeframe { hints.append("- Timeframe: \(timeframe)") }
        if !hints.isEmpty {
            lines.append("Parsed details to honor:")
            lines.append(contentsOf: hints)
            lines.append("")
        }

        lines.append("Your plan MUST include all of these sections, each fully populated:")
        for title in RunOfShowPlan.requiredSectionTitles {
            lines.append("- \(title)")
        }
        lines.append("")
        lines.append(jsonSchemaDescription)
        return lines.joined(separator: "\n")
    }
}
