import SwiftUI

/// The color slot a player's panel is painted in. What each slot looks like,
/// and what it's called, comes from the chosen `ColorTheme`.
enum PlayerColor: String, CaseIterable, Codable, Identifiable {
    case white, blue, black, red, green, orange, purple, teal, pink

    var id: String { rawValue }

    /// Default colors handed to seats 1–6 when the app first runs.
    static let defaults: [PlayerColor] = [.red, .blue, .green, .white, .black, .purple]
}
