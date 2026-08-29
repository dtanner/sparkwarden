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
    /// Per-seat facing overrides carried from game to game, keyed by seat
    /// index, with the day they were last set. They belong to the physical
    /// spot at the table, not the player, so seat swaps leave them alone.
    var rotationOverrides: [Int: Int] = [:]
    var rotationOverridesDate: Date?

    init() {}

    private enum CodingKeys: String, CodingKey {
        case mode, startingLife, playerCount, players, rotationOverrides, rotationOverridesDate
    }

    /// Older saved settings predate rotation overrides, so those keys are
    /// optional on decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(GameMode.self, forKey: .mode)
        startingLife = try container.decode(Int.self, forKey: .startingLife)
        playerCount = try container.decode(Int.self, forKey: .playerCount)
        players = try container.decode([Player].self, forKey: .players)
        rotationOverrides = try container.decodeIfPresent([Int: Int].self, forKey: .rotationOverrides) ?? [:]
        rotationOverridesDate = try container.decodeIfPresent(Date.self, forKey: .rotationOverridesDate)
    }

    var seated: [Player] {
        Array(players.prefix(playerCount))
    }

    static func defaultName(seat: Int) -> String { "Player \(seat + 1)" }

    /// True when any seated player has been given a real name.
    var hasCustomNames: Bool {
        seated.enumerated().contains { $0.element.displayName != Self.defaultName(seat: $0.offset) }
    }

    mutating func swapSeats(_ a: Int, _ b: Int) {
        players.swapAt(a, b)
    }

    /// Facing overrides describe where the device sat that day; a table from
    /// another day is no guide, so overrides expire at midnight.
    mutating func pruneRotationOverrides(now: Date = .now, calendar: Calendar = .current) {
        guard let date = rotationOverridesDate, calendar.isDate(date, inSameDayAs: now) else {
            rotationOverrides = [:]
            rotationOverridesDate = nil
            return
        }
    }

    /// Restores every seat's default "Player N" name; colors are kept.
    mutating func resetNames() {
        for i in players.indices {
            players[i].name = Self.defaultName(seat: i)
        }
    }
}
