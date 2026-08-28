import Foundation

/// Plans the "spinning light" that picks who goes first: a sequence of seats
/// to light up, each held for a delay that grows as the light slows down,
/// ending on the winner.
enum StarterRoulette {
    struct Step: Equatable {
        let seat: Int
        let delay: TimeInterval
    }

    static let minLaps = 3
    static let fastestDelay: TimeInterval = 0.06
    static let slowestDelay: TimeInterval = 0.55

    /// Steps from `start` (the seat currently lit, or nil) around `ring` — the
    /// seats in table order — at least `minLaps` times, decelerating, and
    /// landing on `winner`.
    static func steps(ring: [Int], winner: Int, start: Int? = nil) -> [Step] {
        let count = ring.count
        guard let target = ring.firstIndex(of: winner) else { preconditionFailure("winner not in ring") }
        let current = start.flatMap(ring.firstIndex) ?? (target - 1 + count) % count
        var positions = [(current + 1) % count]
        while positions.count < minLaps * count || positions.last != target {
            positions.append((positions.last! + 1) % count)
        }
        let total = Double(positions.count - 1)
        return positions.enumerated().map { i, position in
            // Quadratic ease-out: quick at the start, lingering at the end.
            let t = total == 0 ? 1 : Double(i) / total
            return Step(seat: ring[position], delay: fastestDelay + (slowestDelay - fastestDelay) * t * t)
        }
    }

    static func steps(ring: [Int], start: Int? = nil, using rng: inout some RandomNumberGenerator) -> [Step] {
        steps(ring: ring, winner: ring.randomElement(using: &rng)!, start: start)
    }
}
