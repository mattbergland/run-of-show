import SwiftUI
import RunOfShowKit

/// Renders a generated plan as a scrollable stack of cards — one per required
/// output section. Used as the "magical output" screen.
struct ResultsView: View {
    let plan: RunOfShowPlan
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                planHeader

                runOfShowCard
                venueCard
                budgetCard
                inviteCard
                staffingCard
                vendorCard
                dayOfCard
                followUpCard

                Spacer(minLength: 8)
            }
            .padding(Theme.Metrics.screenPadding)
        }
        .accessibilityIdentifier("resultsScreen")
        .safeAreaInset(edge: .top) { topBar }
    }

    // MARK: - Header & bar

    private var topBar: some View {
        HStack {
            Button {
                onDone()
            } label: {
                Label("New", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityIdentifier("backButton")
            Spacer()
            Text("Your Plan")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            // Balance the leading button.
            Label("New", systemImage: "chevron.left").opacity(0)
        }
        .padding(.horizontal, Theme.Metrics.screenPadding)
        .padding(.vertical, 12)
        .background(Theme.ink.opacity(0.95))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.hairline), alignment: .bottom)
    }

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.eventTitle)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityIdentifier("planTitle")
            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    // MARK: - Section cards

    private var runOfShowCard: some View {
        SectionCard(icon: "clock.fill", title: "Run of Show", identifier: "card_runOfShow") {
            ForEach(Array(plan.runOfShow.enumerated()), id: \.offset) { _, segment in
                HStack(alignment: .top, spacing: 12) {
                    Text(segment.time)
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.accent)
                        .frame(width: 78, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(segment.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(segment.details)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                        if let mins = segment.durationMinutes {
                            Text("\(mins) min")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary.opacity(0.8))
                        }
                    }
                }
            }
        }
    }

    private var venueCard: some View {
        SectionCard(icon: "building.2.fill", title: "Venue Requirements", identifier: "card_venueRequirements") {
            ForEach(Array(plan.venueRequirements.enumerated()), id: \.offset) { _, req in
                bulletRow(label: req.category, value: req.requirement)
            }
        }
    }

    private var budgetCard: some View {
        SectionCard(icon: "dollarsign.circle.fill", title: "Budget", identifier: "card_budget") {
            ForEach(Array(plan.budget.lineItems.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.item)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                        if let notes = item.notes {
                            Text(notes)
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    Text(currency(item.estimatedCost))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                Divider().overlay(Theme.hairline)
            }
            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(currency(plan.budget.total))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityIdentifier("budgetTotal")
        }
    }

    private var inviteCard: some View {
        SectionCard(icon: "envelope.fill", title: "Invite Copy", identifier: "card_inviteCopy") {
            Text("Subject")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(plan.inviteCopy.subjectLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Divider().overlay(Theme.hairline).padding(.vertical, 4)
            Text(plan.inviteCopy.body)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var staffingCard: some View {
        SectionCard(icon: "person.2.fill", title: "Staffing Plan", identifier: "card_staffingPlan") {
            ForEach(Array(plan.staffingPlan.enumerated()), id: \.offset) { _, role in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(role.role)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        if let count = role.count {
                            Text("×\(count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    Text(role.responsibilities)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var vendorCard: some View {
        SectionCard(icon: "checklist", title: "Vendor Checklist", identifier: "card_vendorChecklist") {
            ForEach(Array(plan.vendorChecklist.enumerated()), id: \.offset) { _, vendor in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "square")
                        .font(.footnote)
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vendor.vendor)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(vendor.whatToConfirm)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    private var dayOfCard: some View {
        SectionCard(icon: "sun.max.fill", title: "Day-of Timeline", identifier: "card_dayOfTimeline") {
            ForEach(Array(plan.dayOfTimeline.enumerated()), id: \.offset) { _, entry in
                HStack(alignment: .top, spacing: 12) {
                    Text(entry.time)
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.accent)
                        .frame(width: 78, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.activity)
                            .font(.footnote)
                            .foregroundStyle(Theme.textPrimary)
                        if let owner = entry.owner {
                            Text(owner)
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var followUpCard: some View {
        SectionCard(icon: "paperplane.fill", title: "Follow-up Plan", identifier: "card_followUpPlan") {
            ForEach(Array(plan.followUpPlan.enumerated()), id: \.offset) { _, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(step.timing)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 100, alignment: .leading)
                    Text(step.action)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func bulletRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(value)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = plan.budget.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

/// Reusable card shell: an icon + title header above arbitrary content.
struct SectionCard<Content: View>: View {
    let icon: String
    let title: String
    let identifier: String
    let content: () -> Content

    init(icon: String, title: String, identifier: String, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.identifier = identifier
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            content()
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    ZStack {
        Theme.backgroundGradient.ignoresSafeArea()
        ResultsView(plan: MockProvider.plan(for: PlanRequest(rawInput: PlanViewModel.exampleInput))) {}
    }
}
