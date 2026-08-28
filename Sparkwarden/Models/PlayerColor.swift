import SwiftUI

/// The palette a player's panel can be painted in. Each color has a resting
/// shade and a "lit" shade used when the starter roulette light is under the
/// panel or the player has just been chosen to go first.
enum PlayerColor: String, CaseIterable, Codable, Identifiable {
    case white, blue, black, red, green, orange, purple, teal, pink

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    /// Hue, saturation, and resting brightness in HSB.
    private var hsb: (h: Double, s: Double, b: Double) {
        switch self {
        case .white:  (0.12, 0.10, 0.85)
        case .blue:   (0.60, 0.80, 0.60)
        case .black:  (0.72, 0.15, 0.22)
        case .red:    (0.00, 0.80, 0.62)
        case .green:  (0.36, 0.75, 0.48)
        case .orange: (0.07, 0.85, 0.75)
        case .purple: (0.78, 0.65, 0.55)
        case .teal:   (0.50, 0.75, 0.52)
        case .pink:   (0.92, 0.60, 0.70)
        }
    }

    func color(lit: Bool) -> Color {
        let c = hsb
        return lit
            ? Color(hue: c.h, saturation: max(c.s - 0.25, 0.05), brightness: min(c.b + 0.35, 1))
            : Color(hue: c.h, saturation: c.s, brightness: c.b)
    }

    /// Foreground color that stays legible on both resting and lit shades.
    var foreground: Color {
        self == .white ? Color(white: 0.12) : .white
    }

    /// Default colors handed to seats 1–6 when the app first runs.
    static let defaults: [PlayerColor] = [.red, .blue, .green, .white, .black, .purple]
}
