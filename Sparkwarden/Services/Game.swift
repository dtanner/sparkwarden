import Foundation

/// A game in progress: the seated players (in seat order) and their counters.
/// Pure value type — every rule about life, poison, and commander damage
/// lives here so it can be tested without any UI.
struct Game: Equatable {
    let mode: GameMode
    let startingLife: Int
    private(set) var players: [Player]
    private(set) var states: [PlayerState]
    /// Per-seat rotation override in degrees, applied on top of the table
    /// layout's default. Keyed by seat index.
    private(set) var rotationOverrides: [Int: Int] = [:]

    init(settings: GameSettings) {
        mode = settings.mode
        startingLife = settings.startingLife
        players = settings.seated
        states = players.map { _ in PlayerState(life: settings.startingLife) }
    }

    var count: Int { players.count }

    subscript(seat: Int) -> PlayerState { states[seat] }

    func opponents(of seat: Int) -> [(seat: Int, player: Player)] {
        players.enumerated().filter { $0.offset != seat }.map { ($0.offset, $0.element) }
    }

    mutating func addLife(_ delta: Int, seat: Int) {
        states[seat].life += delta
    }

    mutating func addPoison(_ delta: Int, seat: Int) {
        states[seat].poison = max(0, states[seat].poison + delta)
    }

    mutating func addCommanderTax(_ delta: Int, seat: Int) {
        states[seat].commanderTax = max(0, states[seat].commanderTax + delta)
    }

    /// Commander damage dealt to `seat` by `attacker`. Damage also comes off
    /// life, and removing damage (a misclick) gives that life back.
    mutating func addCommanderDamage(_ delta: Int, seat: Int, from attacker: Int) {
        let key = players[attacker].id
        let before = states[seat].commanderDamage[key, default: 0]
        let after = max(0, before + delta)
        states[seat].commanderDamage[key] = after
        states[seat].life -= after - before
    }

    func commanderDamage(seat: Int, from attacker: Int) -> Int {
        states[seat].commanderDamage[players[attacker].id, default: 0]
    }

    mutating func update(_ player: Player, seat: Int) {
        players[seat] = player
    }

    mutating func setRotation(_ degrees: Int, seat: Int) {
        rotationOverrides[seat] = degrees
    }

    func rotation(seat: Int, defaultRotation: Int) -> Int {
        rotationOverrides[seat] ?? defaultRotation
    }
}
