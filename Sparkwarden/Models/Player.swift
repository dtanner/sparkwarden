import Foundation

/// A seat's occupant — persisted between games so names and colors stick.
struct Player: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var color: PlayerColor
    /// How many commanders this player runs: 1, or 2 with partners and
    /// similar. Commander damage is tracked per commander.
    var commanderCount = 1

    static let maxCommanders = 2

    init(id: UUID = UUID(), name: String, color: PlayerColor, commanderCount: Int = 1) {
        self.id = id
        self.name = name
        self.color = color
        self.commanderCount = commanderCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, color, commanderCount
    }

    /// Players saved before partner support have no commander count.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(PlayerColor.self, forKey: .color)
        commanderCount = try container.decodeIfPresent(Int.self, forKey: .commanderCount) ?? 1
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}

/// Everything that changes about one player during a game.
struct PlayerState: Equatable, Codable {
    var life: Int
    var poison = 0
    /// Extra mana each commander costs to cast from the command zone, in
    /// steps of 2, one entry per commander the player can run.
    var commanderTax = [Int](repeating: 0, count: Player.maxCommanders)
    /// Commander damage taken, keyed by the attacking player's id, one entry
    /// per commander that player runs. A player's own commander can be in
    /// here too — stolen commanders hit their owner.
    var commanderDamage: [UUID: [Int]] = [:]

    static let poisonLethal = 10
    static let commanderLethal = 21

    var isDead: Bool {
        life <= 0
            || poison >= Self.poisonLethal
            || commanderDamage.values.joined().contains { $0 >= Self.commanderLethal }
    }
}
