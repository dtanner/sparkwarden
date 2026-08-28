import SwiftUI

/// Single source of app state: the persisted setup, the game in progress,
/// and the starter roulette animation.
@MainActor @Observable
final class AppModel {
    private static let settingsKey = "settings"

    var settings: GameSettings {
        didSet { persistSettings() }
    }
    var game: Game?

    /// Seat the roulette light is currently under.
    private(set) var litSeat: Int?
    /// Seat chosen to go first; stays lit until the next life change.
    private(set) var starterSeat: Int?
    private(set) var isSpinning = false
    /// The "who goes first?" prompt shows from game start until someone spins
    /// or dismisses it, or the first counter changes.
    private(set) var showsStarterPrompt = false
    private var spinTask: Task<Void, Never>?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.settingsKey),
           let saved = try? JSONDecoder().decode(GameSettings.self, from: data) {
            settings = saved
        } else {
            settings = GameSettings()
        }
    }

    private func persistSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Self.settingsKey)
        }
    }

    // MARK: Game lifecycle

    func startGame() {
        game = Game(settings: settings)
        starterSeat = nil
        showsStarterPrompt = true
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func endGame() {
        spinTask?.cancel()
        isSpinning = false
        litSeat = nil
        starterSeat = nil
        showsStarterPrompt = false
        game = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    /// Mutates the game in place; any counter change also clears the starter
    /// highlight and prompt — once life moves, the game is under way.
    func modify(_ change: (inout Game) -> Void) {
        guard game != nil else { return }
        change(&game!)
        starterSeat = nil
        showsStarterPrompt = false
    }

    /// Player edits (name, color, facing) don't count as the game starting.
    func edit(_ change: (inout Game) -> Void) {
        guard game != nil else { return }
        change(&game!)
    }

    func dismissStarterPrompt() {
        showsStarterPrompt = false
    }

    /// Edits to a seated player persist to settings so they stick for next game.
    func update(_ player: Player, seat: Int) {
        edit { $0.update(player, seat: seat) }
        if let i = settings.players.firstIndex(where: { $0.id == player.id }) {
            settings.players[i] = player
        }
    }

    func isLit(seat: Int) -> Bool {
        litSeat == seat || starterSeat == seat
    }

    // MARK: Starter roulette

    func spinForStarter() {
        guard let game, !isSpinning else { return }
        isSpinning = true
        starterSeat = nil
        var rng = SystemRandomNumberGenerator()
        let steps = StarterRoulette.steps(count: game.count, start: litSeat, using: &rng)
        spinTask = Task { [weak self] in
            let tick = UISelectionFeedbackGenerator()
            for step in steps {
                guard !Task.isCancelled, let self else { return }
                litSeat = step.seat
                tick.selectionChanged()
                try? await Task.sleep(for: .seconds(step.delay))
            }
            guard !Task.isCancelled, let self else { return }
            // Land: blink the winner a couple of times, then leave it lit.
            let winner = steps.last!.seat
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            for _ in 0..<2 {
                litSeat = nil
                try? await Task.sleep(for: .milliseconds(150))
                litSeat = winner
                try? await Task.sleep(for: .milliseconds(150))
            }
            litSeat = nil
            starterSeat = winner
            isSpinning = false
            showsStarterPrompt = false
        }
    }
}
