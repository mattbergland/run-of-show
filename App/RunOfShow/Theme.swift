import SwiftUI

/// Centralized colors, gradients, and typography for a warm, premium look that
/// matches the "intimate, not too corporate" brand of Run of Show.
enum Theme {
    // Warm, dinner-party palette: deep ink canvas with an amber/terracotta accent.
    static let ink = Color(red: 0.09, green: 0.09, blue: 0.12)
    static let surface = Color(red: 0.14, green: 0.14, blue: 0.18)
    static let surfaceElevated = Color(red: 0.18, green: 0.18, blue: 0.23)
    static let accent = Color(red: 0.93, green: 0.55, blue: 0.30)      // warm amber
    static let accentDeep = Color(red: 0.78, green: 0.36, blue: 0.24)  // terracotta
    static let textPrimary = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let textSecondary = Color(red: 0.74, green: 0.73, blue: 0.70)
    static let hairline = Color.white.opacity(0.08)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [ink, Color(red: 0.13, green: 0.10, blue: 0.12)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Metrics {
        static let cardCornerRadius: CGFloat = 18
        static let cardPadding: CGFloat = 18
        static let screenPadding: CGFloat = 20
    }
}

extension View {
    /// Standard card chrome used by every results section.
    func cardStyle() -> some View {
        self
            .padding(Theme.Metrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cardCornerRadius, style: .continuous))
    }
}
