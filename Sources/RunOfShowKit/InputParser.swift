import Foundation

/// Structured interpretation of the single free-text field the user types.
///
/// The Run of Show app has exactly one input: an event idea *or* a Luma link.
/// `InputParser` turns that raw string into light structure (detected Luma URL,
/// attendee count, location, timeframe, vibe) that the prompt builder and the
/// mock provider can use. It is intentionally forgiving: any field it cannot
/// confidently extract is simply left `nil`.
public struct ParsedInput: Codable, Equatable, Sendable {
    /// The original, untouched text the user entered.
    public var rawText: String
    /// A Luma event link if one was found in the text.
    public var lumaURL: URL?
    /// The descriptive part of the input (raw text with any bare URL removed).
    public var eventDescription: String
    /// Best-effort attendee count (e.g. "30 people" -> 30).
    public var attendeeCount: Int?
    /// Best-effort location (e.g. "in SF" -> "SF").
    public var location: String?
    /// Best-effort timeframe (e.g. "in 3 weeks").
    public var timeframe: String?

    public init(
        rawText: String,
        lumaURL: URL? = nil,
        eventDescription: String,
        attendeeCount: Int? = nil,
        location: String? = nil,
        timeframe: String? = nil
    ) {
        self.rawText = rawText
        self.lumaURL = lumaURL
        self.eventDescription = eventDescription
        self.attendeeCount = attendeeCount
        self.location = location
        self.timeframe = timeframe
    }

    /// True when the input is empty or too short to describe an event.
    public var isTooShort: Bool {
        eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 && lumaURL == nil
    }
}

public enum InputParser {
    /// Parse the single text field into a `ParsedInput`. Never throws — every
    /// extraction is best-effort and degrades gracefully on odd input.
    public static func parse(_ raw: String) -> ParsedInput {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        let lumaURL = firstLumaURL(in: trimmed)
        let description = descriptionRemovingURL(from: trimmed, url: lumaURL)

        return ParsedInput(
            rawText: raw,
            lumaURL: lumaURL,
            eventDescription: description.isEmpty ? trimmed : description,
            attendeeCount: attendeeCount(in: trimmed),
            location: location(in: trimmed),
            timeframe: timeframe(in: trimmed)
        )
    }

    // MARK: - Luma link detection

    private static func firstLumaURL(in text: String) -> URL? {
        // Linux Foundation has no NSDataDetector, so match URLs with a regex.
        let pattern = #"https?://[^\s<>"')]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, options: [], range: range) {
            guard let captured = Range(match.range, in: text) else { continue }
            let token = String(text[captured]).trimmingCharacters(in: CharacterSet(charactersIn: ".,;)]"))
            guard let url = URL(string: token), let host = url.host?.lowercased() else { continue }
            if host.contains("lu.ma") || host.contains("luma") {
                return url
            }
        }
        return nil
    }

    private static func descriptionRemovingURL(from text: String, url: URL?) -> String {
        guard let url else { return text }
        return text
            .replacingOccurrences(of: url.absoluteString, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Attendee count

    private static func attendeeCount(in text: String) -> Int? {
        // Matches "30 people", "for 30", "30 guests", "30-person".
        let patterns = [
            #"(\d{1,5})\s*(?:people|guests|attendees|persons|pax|heads)"#,
            #"(?:for|of|about|~)\s*(\d{1,5})\b"#,
            #"(\d{1,5})\s*-?\s*person"#
        ]
        for pattern in patterns {
            if let value = firstCapturedInt(pattern: pattern, in: text) {
                return value
            }
        }
        return nil
    }

    // MARK: - Location

    private static func location(in text: String) -> String? {
        // Matches "in SF", "in San Francisco,", "in New York." — stops at a
        // sentence boundary so "in SF. Intimate" yields "SF".
        let pattern = #"\bin\s+([A-Z][A-Za-z]*(?:\s+[A-Z][A-Za-z]*){0,3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let captured = Range(match.range(at: 1), in: text) else { return nil }
        let value = String(text[captured]).trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
        // Avoid swallowing trailing words like "in 3 weeks".
        return value.isEmpty ? nil : value
    }

    // MARK: - Timeframe

    private static func timeframe(in text: String) -> String? {
        let pattern = #"(?:in|within|over the next|next)\s+\d+\s*(?:day|week|month)s?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let captured = Range(match.range, in: text) else { return nil }
        return String(text[captured])
    }

    // MARK: - Helpers

    private static func firstCapturedInt(pattern: String, in text: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captured = Range(match.range(at: 1), in: text) else { return nil }
        return Int(text[captured])
    }
}
