import Testing
@testable import Sparkwarden

struct GameSettingsTests {
    @Test func resetNamesRestoresDefaultsAndKeepsColors() {
        var settings = GameSettings()
        settings.players[0].name = "Dan"
        settings.players[3].name = "Kim"
        settings.players[0].color = PlayerColor.defaults[5]
        #expect(settings.hasCustomNames)

        settings.resetNames()

        #expect(!settings.hasCustomNames)
        #expect(settings.players.enumerated().allSatisfy { $0.element.name == GameSettings.defaultName(seat: $0.offset) })
        #expect(settings.players[0].color == PlayerColor.defaults[5])
    }
}
