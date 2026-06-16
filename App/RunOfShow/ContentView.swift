import SwiftUI
import RunOfShowKit

/// Root view. Shows the single input screen and transitions to the results
/// screen once a plan is generated. Loading and error states are handled inline.
struct ContentView: View {
    @StateObject private var viewModel = PlanViewModel()

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            switch viewModel.state {
            case .idle:
                InputView(viewModel: viewModel)
                    .transition(.opacity)
            case .loading:
                LoadingView()
                    .transition(.opacity)
            case .loaded(let plan):
                ResultsView(plan: plan) {
                    withAnimation(.easeInOut) { viewModel.reset() }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .failed(let message):
                ErrorView(message: message) {
                    withAnimation(.easeInOut) { viewModel.reset() }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.state)
        .tint(Theme.accent)
    }
}

/// Full-screen loading state shown while the engine builds the plan.
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(Theme.accent)
            Text("Planning your event…")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Building your run-of-show, budget, staffing and more.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .accessibilityIdentifier("loadingView")
    }
}

/// Inline error state with a way back to the input screen.
struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("We hit a snag")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Back", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentDeep)
        }
        .accessibilityIdentifier("errorView")
    }
}

#Preview {
    ContentView()
}
