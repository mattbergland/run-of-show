import Foundation

// MARK: - Output sections
//
// Every section listed in the Run of Show spec is modeled as its own typed,
// `Codable` value so the UI can render each one as a dedicated card and so the
// AI output can be parsed and round-tripped losslessly.

/// A single segment of the event's minute-by-minute run-of-show.
public struct RunOfShowSegment: Codable, Equatable, Hashable, Sendable {
    public var time: String
    public var title: String
    public var details: String
    public var durationMinutes: Int?

    public init(time: String, title: String, details: String, durationMinutes: Int? = nil) {
        self.time = time
        self.title = title
        self.details = details
        self.durationMinutes = durationMinutes
    }
}

/// A requirement the venue must satisfy (capacity, AV, layout, etc.).
public struct VenueRequirement: Codable, Equatable, Hashable, Sendable {
    public var category: String
    public var requirement: String

    public init(category: String, requirement: String) {
        self.category = category
        self.requirement = requirement
    }
}

/// A single estimated cost in the budget.
public struct BudgetLineItem: Codable, Equatable, Hashable, Sendable {
    public var item: String
    public var estimatedCost: Double
    public var notes: String?

    public init(item: String, estimatedCost: Double, notes: String? = nil) {
        self.item = item
        self.estimatedCost = estimatedCost
        self.notes = notes
    }
}

/// The event budget: line items plus a total in a given currency.
public struct Budget: Codable, Equatable, Hashable, Sendable {
    public var currency: String
    public var lineItems: [BudgetLineItem]
    public var total: Double

    public init(currency: String = "USD", lineItems: [BudgetLineItem], total: Double? = nil) {
        self.currency = currency
        self.lineItems = lineItems
        self.total = total ?? lineItems.reduce(0) { $0 + $1.estimatedCost }
    }

    /// Sum of the line items, useful when validating an AI-provided total.
    public var computedTotal: Double {
        lineItems.reduce(0) { $0 + $1.estimatedCost }
    }
}

/// Ready-to-send invitation copy.
public struct InviteCopy: Codable, Equatable, Hashable, Sendable {
    public var subjectLine: String
    public var body: String

    public init(subjectLine: String, body: String) {
        self.subjectLine = subjectLine
        self.body = body
    }
}

/// A staffing role and the responsibilities attached to it.
public struct StaffRole: Codable, Equatable, Hashable, Sendable {
    public var role: String
    public var responsibilities: String
    public var count: Int?

    public init(role: String, responsibilities: String, count: Int? = nil) {
        self.role = role
        self.responsibilities = responsibilities
        self.count = count
    }
}

/// A vendor to book plus what must be confirmed with them.
public struct VendorItem: Codable, Equatable, Hashable, Sendable {
    public var vendor: String
    public var whatToConfirm: String

    public init(vendor: String, whatToConfirm: String) {
        self.vendor = vendor
        self.whatToConfirm = whatToConfirm
    }
}

/// An entry on the broader day-of logistics timeline (load-in, setup, teardown…).
public struct TimelineEntry: Codable, Equatable, Hashable, Sendable {
    public var time: String
    public var activity: String
    public var owner: String?

    public init(time: String, activity: String, owner: String? = nil) {
        self.time = time
        self.activity = activity
        self.owner = owner
    }
}

/// A post-event follow-up action and when to do it.
public struct FollowUpStep: Codable, Equatable, Hashable, Sendable {
    public var timing: String
    public var action: String

    public init(timing: String, action: String) {
        self.timing = timing
        self.action = action
    }
}

// MARK: - Top-level plan

/// The complete event operating plan. Each property maps to one required
/// output section from the spec and is rendered as its own card in the UI.
public struct RunOfShowPlan: Codable, Equatable, Hashable, Sendable {
    public var eventTitle: String
    public var summary: String
    public var runOfShow: [RunOfShowSegment]
    public var venueRequirements: [VenueRequirement]
    public var budget: Budget
    public var inviteCopy: InviteCopy
    public var staffingPlan: [StaffRole]
    public var vendorChecklist: [VendorItem]
    public var dayOfTimeline: [TimelineEntry]
    public var followUpPlan: [FollowUpStep]

    public init(
        eventTitle: String,
        summary: String,
        runOfShow: [RunOfShowSegment],
        venueRequirements: [VenueRequirement],
        budget: Budget,
        inviteCopy: InviteCopy,
        staffingPlan: [StaffRole],
        vendorChecklist: [VendorItem],
        dayOfTimeline: [TimelineEntry],
        followUpPlan: [FollowUpStep]
    ) {
        self.eventTitle = eventTitle
        self.summary = summary
        self.runOfShow = runOfShow
        self.venueRequirements = venueRequirements
        self.budget = budget
        self.inviteCopy = inviteCopy
        self.staffingPlan = staffingPlan
        self.vendorChecklist = vendorChecklist
        self.dayOfTimeline = dayOfTimeline
        self.followUpPlan = followUpPlan
    }
}

public extension RunOfShowPlan {
    /// The human-readable titles of every required section, in display order.
    /// Used by the UI to render cards and by tests to assert completeness.
    static let requiredSectionTitles: [String] = [
        "Run of Show",
        "Venue Requirements",
        "Budget",
        "Invite Copy",
        "Staffing Plan",
        "Vendor Checklist",
        "Day-of Timeline",
        "Follow-up Plan"
    ]

    /// True when every required section contains at least one entry, i.e. the
    /// plan is fully populated and safe to present as a finished document.
    var isComplete: Bool {
        !runOfShow.isEmpty &&
        !venueRequirements.isEmpty &&
        !budget.lineItems.isEmpty &&
        !inviteCopy.subjectLine.isEmpty &&
        !inviteCopy.body.isEmpty &&
        !staffingPlan.isEmpty &&
        !vendorChecklist.isEmpty &&
        !dayOfTimeline.isEmpty &&
        !followUpPlan.isEmpty
    }
}
