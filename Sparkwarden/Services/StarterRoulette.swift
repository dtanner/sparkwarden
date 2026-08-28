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

    /// Steps from `start` (the seat currently lit, or nil) around the table
    /// at least `minLaps` times, decelerating, and landing on `winner`.
    static func steps(count: Int, winner: Int, start: Int? = nil) -> [Step] {
        precondition(count > 0 && (0..<count).contains(winner))
        let first = ((start ?? (winner - 1)) + 1 + count) % count
        var seats = [first]
        while seats.count < minLaps * count || seats.last != winner {
            seats.append((seats.last! + 1) % count)
        }
        let total = Double(seats.count - 1)
        return seats.enumerated().map { i, seat in
            // Quadratic ease-out: quick at the start, lingering at the end.
            let t = total == 0 ? 1 : Double(i) / total
            return Step(seat: seat, delay: fastestDelay + (slowestDelay - fastestDelay) * t * t)
        }
    }

    static func steps(count: Int, start: Int? = nil, using rng: inout some RandomNumberGenerator) -> [Step] {
        steps(count: count, winner: Int.random(in: 0..<count, using: &rng), start: start)
    }
}
