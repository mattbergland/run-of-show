import SwiftUI
import RunOfShowKit

/// The single-input home screen: one text field, the primary
/// "Generate Run of Show" button, the tagline, and an empty-state hint.
struct InputView: View {
    @ObservedObject var viewModel: PlanViewModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                inputCard

                generateButton

                exampleHint

                Spacer(minLength: 12)
            }
            .padding(Theme.Metrics.screenPadding)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Run of Show")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityIdentifier("appTitle")
            Text("Turn any event idea into a day-of plan.")
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .accessibilityIdentifier("tagline")
            Text("Type one sentence. Get a complete event operating plan — run-of-show, budget, staffing, vendors, invites and follow-up.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR EVENT IDEA")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.2)

            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("e.g. \(PlanViewModel.exampleInput)")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.horizontal, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.inputText)
                    .focused($inputFocused)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .accessibilityIdentifier("eventInput")
            }
            .padding(8)
            .background(Theme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("An event idea or a Luma link.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
    }

    private var generateButton: some View {
        Button {
            inputFocused = false
            viewModel.generate()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate Run of Show")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accentGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        .accessibilityIdentifier("generateButton")
    }

    private var exampleHint: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.accent)
                Text("Not sure where to start?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("\u{201C}\(PlanViewModel.exampleInput)\u{201D}")
                .font(.callout)
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                viewModel.useExample()
            } label: {
                Text("Use this example")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityIdentifier("useExampleButton")
        }
        .cardStyle()
    }
}

#Preview {
    ZStack {
        Theme.backgroundGradient.ignoresSafeArea()
        InputView(viewModel: PlanViewModel())
    }
}
