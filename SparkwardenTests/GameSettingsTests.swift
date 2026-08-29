import Foundation
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

    @Test func rotationOverridesSurviveWithinTheSameDay() {
        var settings = GameSettings()
        settings.rotationOverrides = [0: 90]
        settings.rotationOverridesDate = .now

        settings.pruneRotationOverrides()

        #expect(settings.rotationOverrides == [0: 90])
    }

    @Test func rotationOverridesExpireOnALaterDay() {
        var settings = GameSettings()
        settings.rotationOverrides = [0: 90]
        settings.rotationOverridesDate = .now

        settings.pruneRotationOverrides(now: .now.addingTimeInterval(60 * 60 * 24 * 2))

        #expect(settings.rotationOverrides.isEmpty)
        #expect(settings.rotationOverridesDate == nil)
    }

    @Test func undatedRotationOverridesAreDropped() {
        var settings = GameSettings()
        settings.rotationOverrides = [1: 180]

        settings.pruneRotationOverrides()

        #expect(settings.rotationOverrides.isEmpty)
    }

    @Test func rotationOverridesRoundTripThroughJSON() throws {
        var settings = GameSettings()
        settings.rotationOverrides = [2: 270]
        settings.rotationOverridesDate = .now

        let decoded = try JSONDecoder().decode(GameSettings.self, from: JSONEncoder().encode(settings))

        #expect(decoded == settings)
    }

    @Test func settingsSavedBeforeRotationOverridesStillDecode() throws {
        var settings = GameSettings()
        settings.rotationOverrides = [0: 90]
        settings.rotationOverridesDate = .now
        var legacy = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any])
        legacy.removeValue(forKey: "rotationOverrides")
        legacy.removeValue(forKey: "rotationOverridesDate")

        let decoded = try JSONDecoder().decode(
            GameSettings.self, from: JSONSerialization.data(withJSONObject: legacy))

        #expect(decoded.rotationOverrides.isEmpty)
        #expect(decoded.rotationOverridesDate == nil)
    }
}
