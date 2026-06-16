import Foundation

/// Robustly extracts a `RunOfShowPlan` from a raw model response that is
/// *supposed* to be pure JSON but in practice may be wrapped in markdown
/// fences or surrounded by stray prose. Tries progressively looser strategies
/// and throws only when none succeed.
public enum JSONExtractor {
    public static func decodePlan(from raw: String) throws -> RunOfShowPlan {
        let decoder = JSONDecoder()
        for candidate in candidates(from: raw) {
            guard let data = candidate.data(using: .utf8) else { continue }
            if let plan = try? decoder.decode(RunOfShowPlan.self, from: data) {
                return plan
            }
        }
        throw AIProviderError.parsingFailed(
            "Could not decode a RunOfShowPlan from the model response."
        )
    }

    /// Ordered list of candidate JSON strings, from most to least specific.
    static func candidates(from raw: String) -> [String] {
        var result: [String] = []
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        result.append(trimmed)

        // Strip a ```json ... ``` or ``` ... ``` fence if present.
        if let fenced = fencedContent(in: trimmed) {
            result.append(fenced.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        // Fall back to the substring between the first '{' and the last '}'.
        if let first = trimmed.firstIndex(of: "{"),
           let last = trimmed.lastIndex(of: "}"),
           first < last {
            result.append(String(trimmed[first...last]))
        }

        return result
    }

    private static func fencedContent(in text: String) -> String? {
        guard let open = text.range(of: "```") else { return nil }
        // Skip an optional language tag on the opening fence line.
        var contentStart = open.upperBound
        if let newline = text[contentStart...].firstIndex(of: "\n") {
            let langTag = text[contentStart..<newline].trimmingCharacters(in: .whitespaces)
            if langTag.count <= 12 && !langTag.contains("{") {
                contentStart = text.index(after: newline)
            }
        }
        guard let close = text.range(of: "```", range: contentStart..<text.endIndex) else {
            return nil
        }
        return String(text[contentStart..<close.lowerBound])
    }
}
