import Foundation

/// A seat's occupant — persisted between games so names and colors stick.
struct Player: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var color: PlayerColor

    var displayName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
}

/// Everything that changes about one player during a game.
struct PlayerState: Equatable, Codable {
    var life: Int
    var poison = 0
    /// Total commander tax paid so far, in mana (steps of 2).
    var commanderTax = 0
    /// Commander damage taken, keyed by the attacking player's id.
    var commanderDamage: [UUID: Int] = [:]

    static let poisonLethal = 10
    static let commanderLethal = 21

    var isDead: Bool {
        life <= 0
            || poison >= Self.poisonLethal
            || commanderDamage.values.contains { $0 >= Self.commanderLethal }
    }
}
