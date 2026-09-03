import Foundation

/// Where each seat's panel goes on screen and which way it faces.
///
/// Rotation is in degrees clockwise; 0 faces the bottom edge of the screen,
/// 90 faces the left edge, 180 the top, 270 the right. Panels are arranged in
/// `groups` — rows stacked top-to-bottom in portrait, columns left-to-right in
/// landscape — and every panel in a layout gets an equal share of the screen.
struct TableLayout: Equatable {
    struct Slot: Equatable {
        let seat: Int
        let rotation: Int
    }

    let groups: [[Slot]]
    let isLandscape: Bool

    static func layout(count: Int, landscape: Bool) -> TableLayout {
        let rows = portraitRows(count: count)
        guard landscape else { return TableLayout(groups: rows, isLandscape: false) }
        // Landscape is the portrait arrangement turned a quarter turn
        // counter-clockwise: rows become columns, the top row becomes the left
        // column, and within a column the former left-most slot is at the bottom.
        let columns = rows.map { row in
            row.reversed().map { Slot(seat: $0.seat, rotation: ($0.rotation + 270) % 360) }
        }
        return TableLayout(groups: columns, isLandscape: true)
    }

    /// Portrait: players sit along the two long sides of the device, with the
    /// odd player out at the top end.
    private static func portraitRows(count: Int) -> [[Slot]] {
        func pair(_ i: Int) -> [Slot] {
            [Slot(seat: i, rotation: 90), Slot(seat: i + 1, rotation: 270)]
        }
        switch count {
        case ...1: return [[Slot(seat: 0, rotation: 0)]]
        case 2: return [[Slot(seat: 0, rotation: 180)], [Slot(seat: 1, rotation: 0)]]
        case 3: return [[Slot(seat: 0, rotation: 180)], pair(1)]
        case 4: return [pair(0), pair(2)]
        case 5: return [[Slot(seat: 0, rotation: 180)], pair(1), pair(3)]
        default: return [pair(0), pair(2), pair(4)]
        }
    }

    /// Seats in clockwise order around the table, starting at the top-left
    /// panel in portrait. Landscape is a rotation of the portrait arrangement,
    /// so the order is the same in either orientation.
    static func clockwiseSeats(count: Int) -> [Int] {
        let rows = portraitRows(count: count)
        var ring = rows[0].map(\.seat)
        // Down the right side, back along the bottom, and up the left side.
        ring += rows.dropFirst().map { $0.last!.seat }
        ring += rows.last!.dropLast().reversed().map(\.seat)
        ring += rows.dropFirst().dropLast().reversed().compactMap { $0.count > 1 ? $0.first!.seat : nil }
        return ring
    }

    func defaultRotation(seat: Int) -> Int {
        groups.joined().first { $0.seat == seat }?.rotation ?? 0
    }

    /// The screen edges a seat's panel touches — the only directions it makes
    /// sense for that panel to face. A top-left panel can face left or top;
    /// a full-width panel at the top can also face either side.
    func facings(seat: Int) -> [Facing] {
        guard let g = groups.firstIndex(where: { $0.contains { $0.seat == seat } }),
              let i = groups[g].firstIndex(where: { $0.seat == seat }) else { return Facing.allCases }
        let firstGroup = g == 0, lastGroup = g == groups.count - 1
        let firstInGroup = i == 0, lastInGroup = i == groups[g].count - 1
        var edges: [Facing] = []
        if isLandscape {
            if firstGroup { edges.append(.left) }
            if lastGroup { edges.append(.right) }
            if firstInGroup { edges.append(.top) }
            if lastInGroup { edges.append(.bottom) }
        } else {
            if firstGroup { edges.append(.top) }
            if lastGroup { edges.append(.bottom) }
            if firstInGroup { edges.append(.left) }
            if lastInGroup { edges.append(.right) }
        }
        return Facing.allCases.filter(edges.contains)
    }
}

extension TableLayout {
    /// The outer screen edge a panel's floating labels should sit toward, so
    /// they stay clear of the center controls on the seam between the first
    /// two groups. Portrait: top for the first row, bottom otherwise; landscape:
    /// left for the first column, right otherwise.
    func outerEdge(seat: Int) -> Facing {
        let inFirstGroup = groups.first?.contains { $0.seat == seat } ?? false
        if isLandscape { return inFirstGroup ? .left : .right }
        return inFirstGroup ? .top : .bottom
    }
}

/// The screen edge a panel is turned toward, as the panel's rotation in degrees.
enum Facing: Int, CaseIterable, Identifiable {
    case top = 180, left = 90, bottom = 0, right = 270

    var id: Int { rawValue }
    var rotation: Int { rawValue }

    var label: String {
        switch self {
        case .bottom: "Bottom edge"
        case .left: "Left edge"
        case .top: "Top edge"
        case .right: "Right edge"
        }
    }

    /// The screen edge a panel's content-leading side points to when the
    /// panel is rotated by `rotation` degrees clockwise.
    static func leadingEdge(rotation: Int) -> Facing {
        switch rotation % 360 {
        case 90: .top
        case 180: .right
        case 270: .bottom
        default: .left
        }
    }

    /// The screen edge a panel's top points to when the panel is rotated by
    /// `rotation` degrees clockwise.
    static func topEdge(rotation: Int) -> Facing {
        (Facing(rawValue: rotation % 360) ?? .bottom).opposite
    }

    var opposite: Facing {
        switch self {
        case .top: .bottom
        case .bottom: .top
        case .left: .right
        case .right: .left
        }
    }

    var systemImage: String {
        switch self {
        case .bottom: "arrow.down"
        case .left: "arrow.left"
        case .top: "arrow.up"
        case .right: "arrow.right"
        }
    }
}
