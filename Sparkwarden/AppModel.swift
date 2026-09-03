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
    /// Seat whose focus view fills the screen, if any. It closes itself after
    /// a pause without counter changes, since it hides everyone else's totals.
    private(set) var focusedSeat: Int?
    /// The idle close is moments away; the focus view dims as a warning so
    /// nobody taps into the table underneath by surprise.
    private(set) var focusClosingSoon = false
    private var focusCloseTask: Task<Void, Never>?
    private static let focusIdle: Duration = .seconds(20)
    private static let focusWarning: Duration = .seconds(3)

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
        settings.pruneRotationOverrides()
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
        unfocus()
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
        if focusedSeat != nil { armFocusTimer() }
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

    /// Seat swaps persist too, so the table comes back the same next game.
    func swapSeats(_ a: Int, _ b: Int) {
        edit { $0.swapSeats(a, b) }
        settings.swapSeats(a, b)
    }

    /// Facing choices persist so the seat faces the same way next game;
    /// they expire after the day they were set.
    func setRotation(_ degrees: Int, seat: Int) {
        edit { $0.setRotation(degrees, seat: seat) }
        settings.rotationOverrides[seat] = degrees
        settings.rotationOverridesDate = .now
    }

    func isLit(seat: Int) -> Bool {
        litSeat == seat || starterSeat == seat
    }

    // MARK: Focus view

    func focus(seat: Int) {
        guard let game, game.mode == .commander, seat < game.count else { return }
        focusedSeat = seat
        armFocusTimer()
    }

    func unfocus() {
        holdFocus()
        focusedSeat = nil
    }

    /// Stops the idle close while the player edit sheet is up over the focus
    /// view; `touchFocus` starts it again when the sheet goes away.
    func holdFocus() {
        focusCloseTask?.cancel()
        focusClosingSoon = false
    }

    func touchFocus() {
        if focusedSeat != nil { armFocusTimer() }
    }

    private func armFocusTimer() {
        holdFocus()
        focusCloseTask = Task { [weak self] in
            try? await Task.sleep(for: Self.focusIdle - Self.focusWarning)
            guard !Task.isCancelled else { return }
            self?.focusClosingSoon = true
            try? await Task.sleep(for: Self.focusWarning)
            guard !Task.isCancelled else { return }
            self?.unfocus()
        }
    }

    // MARK: Starter roulette

    func spinForStarter() {
        guard let game, !isSpinning else { return }
        isSpinning = true
        starterSeat = nil
        var rng = SystemRandomNumberGenerator()
        let steps = StarterRoulette.steps(ring: TableLayout.clockwiseSeats(count: game.count), start: litSeat, using: &rng)
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
