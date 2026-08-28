import Testing
@testable import Sparkwarden

struct StarterRouletteTests {
    @Test(arguments: [2, 4, 6]) func landsOnWinnerAfterEnoughLaps(count: Int) {
        for winner in 0..<count {
            let steps = StarterRoulette.steps(ring: Array(0..<count), winner: winner)
            #expect(steps.last?.seat == winner)
            #expect(steps.count >= StarterRoulette.minLaps * count)
            #expect(steps.count < (StarterRoulette.minLaps + 1) * count)
        }
    }

    @Test func visitsRingInOrderStartingAfterCurrent() {
        let ring = [0, 1, 3, 2]
        let steps = StarterRoulette.steps(ring: ring, winner: 2, start: 3)
        #expect(steps.first?.seat == 2)
        for (a, b) in zip(steps, steps.dropFirst()) {
            #expect(b.seat == ring[(ring.firstIndex(of: a.seat)! + 1) % 4])
        }
    }

    @Test func slowsDownMonotonically() {
        let steps = StarterRoulette.steps(ring: [0, 2, 4, 3, 1], winner: 1)
        let delays = steps.map(\.delay)
        #expect(delays == delays.sorted())
        #expect(delays.first == StarterRoulette.fastestDelay)
        #expect(abs(delays.last! - StarterRoulette.slowestDelay) < 0.0001)
    }

    @Test func seededRandomIsDeterministic() {
        struct Fixed: RandomNumberGenerator { func next() -> UInt64 { 7 } }
        var a = Fixed(), b = Fixed()
        #expect(StarterRoulette.steps(ring: Array(0..<6), using: &a) == StarterRoulette.steps(ring: Array(0..<6), using: &b))
    }
}
