import Foundation
import Testing
@testable import Sparkwarden

struct GameTests {
    private func makeGame(mode: GameMode = .casual, count: Int = 4) -> Game {
        var settings = GameSettings()
        settings.mode = mode
        settings.startingLife = mode.defaultStartingLife
        settings.playerCount = count
        return Game(settings: settings)
    }

    @Test func startsEveryoneAtStartingLife() {
        let game = makeGame(mode: .commander, count: 5)
        #expect(game.count == 5)
        #expect(game.states.allSatisfy { $0.life == 40 && $0.poison == 0 })
    }

    @Test func lifeAndPoisonDeath() {
        var game = makeGame()
        game.addLife(-20, seat: 0)
        #expect(game[0].isDead)
        game.addLife(1, seat: 0)
        #expect(!game[0].isDead)
        game.addPoison(10, seat: 1)
        #expect(game[1].isDead)
        game.addPoison(-11, seat: 1)
        #expect(game[1].poison == 0)
    }

    @Test func commanderDamageAlsoReducesLife() {
        var game = makeGame(mode: .commander)
        game.addCommanderDamage(5, seat: 0, from: 1)
        #expect(game[0].life == 35)
        #expect(game.commanderDamage(seat: 0, from: 1) == 5)
        game.addCommanderDamage(-7, seat: 0, from: 1)
        #expect(game.commanderDamage(seat: 0, from: 1) == 0)
        #expect(game[0].life == 40)
        game.addCommanderDamage(21, seat: 0, from: 2)
        #expect(game[0].isDead)
    }

    @Test func commanderTaxNeverNegative() {
        var game = makeGame(mode: .commander)
        game.addCommanderTax(-2, seat: 0)
        #expect(game[0].commanderTax == 0)
        game.addCommanderTax(2, seat: 0)
        #expect(game[0].commanderTax == 2)
    }

    @Test func rotationOverridesCarryOverFromSettings() {
        var settings = GameSettings()
        settings.rotationOverrides = [1: 90]
        let game = Game(settings: settings)
        #expect(game.rotation(seat: 1, defaultRotation: 270) == 90)
    }

    @Test func rotationOverrideReplacesLayoutDefault() {
        var game = makeGame()
        #expect(game.rotation(seat: 0, defaultRotation: 90) == 90)
        game.setRotation(180, seat: 0)
        #expect(game.rotation(seat: 0, defaultRotation: 90) == 180)
        #expect(game.rotation(seat: 1, defaultRotation: 270) == 270)
    }

    @Test func customNamesEnableReordering() {
        var settings = GameSettings()
        #expect(!settings.hasCustomNames)
        settings.players[1].name = "Dan"
        #expect(settings.hasCustomNames)
        settings.playerCount = 1
        #expect(!settings.hasCustomNames)
    }
}

extension GameTests {
    @Test func swapSeatsMovesPlayersWithTheirCounters() {
        var game = makeGame(mode: .commander, count: 3)
        let (a, b) = (game.players[0], game.players[2])
        game.addLife(-7, seat: 0)
        game.addCommanderDamage(5, seat: 2, from: 1)
        game.setRotation(90, seat: 0)

        game.swapSeats(0, 2)

        #expect(game.players[0] == b && game.players[2] == a)
        #expect(game[2].life == 33)
        #expect(game[0].life == 35)
        #expect(game.commanderDamage(seat: 0, from: 1) == 5)
        #expect(game.rotation(seat: 0, defaultRotation: 0) == 90)
        #expect(game.rotation(seat: 2, defaultRotation: 0) == 0)
    }
}
