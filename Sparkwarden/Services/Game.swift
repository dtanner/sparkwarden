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
    private(set) var rotationOverrides: [Int: Int]

    init(settings: GameSettings) {
        mode = settings.mode
        startingLife = settings.startingLife
        players = settings.seated
        states = players.map { _ in PlayerState(life: settings.startingLife) }
        rotationOverrides = settings.rotationOverrides
    }

    var count: Int { players.count }

    subscript(seat: Int) -> PlayerState { states[seat] }

    /// One commander at the table; partners give a player a second.
    struct Commander: Identifiable, Hashable {
        let seat: Int
        let index: Int
        let player: Player

        var id: String { "\(player.id)-\(index)" }
    }

    /// Every commander that can deal `seat` commander damage: each opponent's
    /// commanders in seat order, then the seat's own (a stolen commander hits
    /// its owner).
    func damageSources(for seat: Int) -> [Commander] {
        let all = players.enumerated().flatMap { s, player in
            (0..<player.commanderCount).map { Commander(seat: s, index: $0, player: player) }
        }
        return all.filter { $0.seat != seat } + all.filter { $0.seat == seat }
    }

    mutating func addLife(_ delta: Int, seat: Int) {
        states[seat].life += delta
    }

    mutating func addPoison(_ delta: Int, seat: Int) {
        states[seat].poison = max(0, states[seat].poison + delta)
    }

    /// Tax is per commander: each cast of one commander costs 2 more per
    /// previous cast of that same commander.
    mutating func addCommanderTax(_ delta: Int, seat: Int, commander: Int = 0) {
        states[seat].commanderTax[commander] = max(0, states[seat].commanderTax[commander] + delta)
    }

    func commanderTax(seat: Int, commander: Int = 0) -> Int {
        states[seat].commanderTax[commander]
    }

    /// Commander damage dealt to `seat` by `attacker`'s commander number
    /// `commander`. Damage also comes off life, and removing damage (a
    /// misclick) gives that life back.
    mutating func addCommanderDamage(_ delta: Int, seat: Int, from attacker: Int, commander: Int = 0) {
        setCommanderDamage(max(0, commanderDamage(seat: seat, from: attacker, commander: commander) + delta),
                           seat: seat, from: players[attacker].id, commander: commander)
    }

    mutating func addCommanderDamage(_ delta: Int, seat: Int, from source: Commander) {
        addCommanderDamage(delta, seat: seat, from: source.seat, commander: source.index)
    }

    func commanderDamage(seat: Int, from attacker: Int, commander: Int = 0) -> Int {
        commanderDamage(seat: seat, from: players[attacker].id, commander: commander)
    }

    func commanderDamage(seat: Int, from source: Commander) -> Int {
        commanderDamage(seat: seat, from: source.player.id, commander: source.index)
    }

    private func commanderDamage(seat: Int, from attacker: UUID, commander: Int) -> Int {
        let damage = states[seat].commanderDamage[attacker] ?? []
        return commander < damage.count ? damage[commander] : 0
    }

    private mutating func setCommanderDamage(_ value: Int, seat: Int, from attacker: UUID, commander: Int) {
        var damage = states[seat].commanderDamage[attacker] ?? []
        while damage.count <= commander { damage.append(0) }
        states[seat].life -= value - damage[commander]
        damage[commander] = value
        states[seat].commanderDamage[attacker] = damage
    }

    /// Replaces a seat's player. A commander the player no longer runs has
    /// its tax reset and its damage cleared (giving that life back), so
    /// nothing hidden can kill.
    mutating func update(_ player: Player, seat: Int) {
        players[seat] = player
        for commander in player.commanderCount..<Player.maxCommanders {
            states[seat].commanderTax[commander] = 0
            for s in states.indices
            where commanderDamage(seat: s, from: player.id, commander: commander) > 0 {
                setCommanderDamage(0, seat: s, from: player.id, commander: commander)
            }
        }
    }

    /// Two players trade seats, taking their counters with them. Rotation
    /// overrides belong to the physical seat and stay put.
    mutating func swapSeats(_ a: Int, _ b: Int) {
        players.swapAt(a, b)
        states.swapAt(a, b)
    }

    mutating func setRotation(_ degrees: Int, seat: Int) {
        rotationOverrides[seat] = degrees
    }

    func rotation(seat: Int, defaultRotation: Int) -> Int {
        rotationOverrides[seat] ?? defaultRotation
    }
}
