import Foundation

/// Fully deterministic, offline provider. Returns a realistic, demoable plan
/// based on the "AI founder dinner" example from the spec, lightly adapted to
/// echo any attendee count / location / timeframe parsed from the input.
///
/// Used by unit tests and SwiftUI previews. Requires no network and no API key.
public struct MockProvider: AIProvider {
    public init() {}

    public func generatePlan(for request: PlanRequest) async throws -> RunOfShowPlan {
        Self.plan(for: request)
    }

    /// Synchronous builder so previews and tests can call it directly.
    public static func plan(for request: PlanRequest) -> RunOfShowPlan {
        let parsed = request.parsed
        let guests = parsed.attendeeCount ?? 30
        let location = parsed.location ?? "SF"
        let timeframe = parsed.timeframe ?? "in 3 weeks"

        return RunOfShowPlan(
            eventTitle: "AI Founder Dinner — \(location)",
            summary: "An intimate, premium dinner for \(guests) AI founders and operators \(location.isEmpty ? "" : "in \(location) ")— warm and conversational, not corporate. Designed to be pulled off \(timeframe).",
            runOfShow: [
                RunOfShowSegment(time: "6:30 PM", title: "Doors & welcome drinks", details: "Guests arrive to a hosted bar. Greeter checks names against the list; host makes warm 1:1 introductions.", durationMinutes: 30),
                RunOfShowSegment(time: "7:00 PM", title: "Seated dinner begins", details: "Guests find seats via place cards arranged to mix backgrounds. First course served family-style.", durationMinutes: 15),
                RunOfShowSegment(time: "7:15 PM", title: "Host welcome & icebreaker", details: "Host welcomes the room (2 min), frames the night, and kicks off a one-sentence go-around: name, company, one hard problem.", durationMinutes: 20),
                RunOfShowSegment(time: "7:35 PM", title: "Main course & guided conversation", details: "Entrées served. Host seeds 2–3 discussion prompts on building in AI; lets conversation flow between tables.", durationMinutes: 50),
                RunOfShowSegment(time: "8:25 PM", title: "Dessert & open networking", details: "Dessert and coffee. Guests free to move seats; host connects people with shared interests.", durationMinutes: 35),
                RunOfShowSegment(time: "9:00 PM", title: "Closing toast", details: "Host gives a short closing toast, thanks guests, and shares one clear next step (group chat / next dinner).", durationMinutes: 10),
                RunOfShowSegment(time: "9:10 PM", title: "Soft close & departures", details: "Bar stays open 20 more minutes for stragglers; team begins quiet breakdown.", durationMinutes: 20)
            ],
            venueRequirements: [
                VenueRequirement(category: "Capacity", requirement: "Private room comfortably seating \(guests) at one long table or 3–4 rounds."),
                VenueRequirement(category: "Ambiance", requirement: "Warm, dim lighting; low background music; not a loud or echoey space."),
                VenueRequirement(category: "Layout", requirement: "Single shared table preferred to keep one conversation; space for a welcome-drinks area near the entrance."),
                VenueRequirement(category: "A/V", requirement: "No stage needed. Optional small speaker for background music and the host's welcome."),
                VenueRequirement(category: "Catering", requirement: "Family-style or plated multi-course menu with vegetarian and dietary options; hosted bar."),
                VenueRequirement(category: "Accessibility", requirement: "Step-free access and an accessible restroom.")
            ],
            budget: Budget(
                currency: "USD",
                lineItems: [
                    BudgetLineItem(item: "Venue / private room fee", estimatedCost: 1500, notes: "Often waived with F&B minimum."),
                    BudgetLineItem(item: "Food (\(guests) × $95)", estimatedCost: Double(guests) * 95, notes: "Multi-course, family-style."),
                    BudgetLineItem(item: "Beverages / hosted bar (\(guests) × $45)", estimatedCost: Double(guests) * 45, notes: "Wine, beer, N/A options."),
                    BudgetLineItem(item: "Staffing (host help + server gratuity)", estimatedCost: 600, notes: "On top of venue staff."),
                    BudgetLineItem(item: "Florals & candles", estimatedCost: 350, notes: "Low arrangements so guests can see each other."),
                    BudgetLineItem(item: "Place cards & printed menus", estimatedCost: 150, notes: "Adds a premium, intentional touch."),
                    BudgetLineItem(item: "Photographer (2 hrs)", estimatedCost: 500, notes: "Candid only, no flash."),
                    BudgetLineItem(item: "Contingency (~10%)", estimatedCost: 700, notes: "Buffer for overages.")
                ]
            ),
            inviteCopy: InviteCopy(
                subjectLine: "Dinner with \(guests) AI founders \(location.isEmpty ? "" : "in \(location) ")— you're invited",
                body: """
                Hi {{first_name}},

                I'm hosting an intimate dinner for a small group of AI founders and operators \(location.isEmpty ? "" : "in \(location) ")and would love for you to join.

                No agenda, no pitches — just great food and an honest conversation about what's actually working (and what isn't) as we build. Just \(guests) of us around one table.

                When: {{date}} at 6:30 PM
                Where: {{venue}} (private room)
                Dress: Smart casual

                Space is limited and seats are assigned, so a quick yes/no helps a ton. Can you make it?

                Warmly,
                {{host_name}}
                """
            ),
            staffingPlan: [
                StaffRole(role: "Host / MC", responsibilities: "Owns the room: welcomes guests, makes introductions, seeds conversation, gives the toast.", count: 1),
                StaffRole(role: "Greeter / check-in", responsibilities: "Manages the door and guest list, hands out name cards, points guests to drinks.", count: 1),
                StaffRole(role: "Floor lead", responsibilities: "Coordinates with venue on timing of courses, watches energy, signals transitions to host.", count: 1),
                StaffRole(role: "Photographer", responsibilities: "Captures candid moments for follow-up and future invites; stays unobtrusive.", count: 1)
            ],
            vendorChecklist: [
                VendorItem(vendor: "Restaurant / venue", whatToConfirm: "Private room, headcount, F&B minimum, menu, timing, and final guarantee date."),
                VendorItem(vendor: "Caterer / kitchen", whatToConfirm: "Menu tasting, dietary accommodations (veg/vegan/GF), and course pacing."),
                VendorItem(vendor: "Bar service", whatToConfirm: "Hosted bar package, wine selections, and non-alcoholic options."),
                VendorItem(vendor: "Florist", whatToConfirm: "Low table arrangements, delivery/setup time, and candle safety with venue."),
                VendorItem(vendor: "Photographer", whatToConfirm: "2-hour candid coverage, no-flash policy, and delivery turnaround."),
                VendorItem(vendor: "Print / stationery", whatToConfirm: "Place cards and printed menus; final spelling of guest names.")
            ],
            dayOfTimeline: [
                TimelineEntry(time: "3:00 PM", activity: "Team arrives; confirm final headcount and seating chart with venue.", owner: "Floor lead"),
                TimelineEntry(time: "3:30 PM", activity: "Florals and candles delivered and placed; menus and place cards set.", owner: "Greeter"),
                TimelineEntry(time: "4:30 PM", activity: "Walkthrough: lighting, music level, bar setup, restroom signage.", owner: "Host"),
                TimelineEntry(time: "5:30 PM", activity: "Final menu/timing check with kitchen; brief all staff on the run-of-show.", owner: "Floor lead"),
                TimelineEntry(time: "6:15 PM", activity: "Check-in table live; music on; bar ready.", owner: "Greeter"),
                TimelineEntry(time: "6:30 PM", activity: "Doors open — event begins.", owner: "Host"),
                TimelineEntry(time: "9:30 PM", activity: "Guests depart; collect items, settle invoice, confirm photo delivery.", owner: "Floor lead")
            ],
            followUpPlan: [
                FollowUpStep(timing: "That night", action: "Send a short thank-you text to every guest while the evening is fresh."),
                FollowUpStep(timing: "Within 24 hours", action: "Email recap with 2–3 standout takeaways and a few candid photos."),
                FollowUpStep(timing: "Within 48 hours", action: "Make the introductions you promised at dinner, one warm email each."),
                FollowUpStep(timing: "Within 1 week", action: "Spin up a small group chat so the connections keep going."),
                FollowUpStep(timing: "Within 2 weeks", action: "Send a 3-question feedback form and note ideas for the next dinner.")
            ]
        )
    }
}
