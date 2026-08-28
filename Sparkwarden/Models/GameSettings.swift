import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case casual, commander

    var id: String { rawValue }

    var label: String {
        switch self {
        case .casual: "Casual"
        case .commander: "Commander"
        }
    }

    var defaultStartingLife: Int {
        switch self {
        case .casual: 20
        case .commander: 40
        }
    }
}

/// Persisted setup: mode, starting life, and the roster of seats. `players`
/// always holds `maxPlayers` entries; the first `playerCount` are seated.
struct GameSettings: Codable, Equatable {
    static let minPlayers = 2
    static let maxPlayers = 6
    static let lifeRange = 1...999

    var mode: GameMode = .casual
    var startingLife = GameMode.casual.defaultStartingLife
    var playerCount = 4
    var players: [Player] = (0..<maxPlayers).map {
        Player(name: defaultName(seat: $0), color: PlayerColor.defaults[$0])
    }

    var seated: [Player] {
        Array(players.prefix(playerCount))
    }

    static func defaultName(seat: Int) -> String { "Player \(seat + 1)" }

    /// True when any seated player has been given a real name; with default
    /// names there's nothing meaningful to reorder.
    var hasCustomNames: Bool {
        seated.enumerated().contains { $0.element.displayName != Self.defaultName(seat: $0.offset) }
    }
}
