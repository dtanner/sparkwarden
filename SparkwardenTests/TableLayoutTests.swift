import Testing
@testable import Sparkwarden

struct TableLayoutTests {
    @Test(arguments: 2...6) func everySeatAppearsOnce(count: Int) {
        for landscape in [false, true] {
            let seats = TableLayout.layout(count: count, landscape: landscape).groups.joined().map(\.seat).sorted()
            #expect(seats == Array(0..<count))
        }
    }

    @Test func clockwiseSeatsGoAroundTheTable() {
        #expect(TableLayout.clockwiseSeats(count: 2) == [0, 1])
        #expect(TableLayout.clockwiseSeats(count: 3) == [0, 2, 1])
        #expect(TableLayout.clockwiseSeats(count: 4) == [0, 1, 3, 2])
        #expect(TableLayout.clockwiseSeats(count: 5) == [0, 2, 4, 3, 1])
        #expect(TableLayout.clockwiseSeats(count: 6) == [0, 1, 3, 5, 4, 2])
    }

    @Test func portraitFourFacesTheLongSides() {
        let layout = TableLayout.layout(count: 4, landscape: false)
        #expect(layout.groups == [
            [.init(seat: 0, rotation: 90), .init(seat: 1, rotation: 270)],
            [.init(seat: 2, rotation: 90), .init(seat: 3, rotation: 270)],
        ])
    }

    @Test func landscapeTwoFacesLeftAndRight() {
        let layout = TableLayout.layout(count: 2, landscape: true)
        #expect(layout.isLandscape)
        #expect(layout.groups == [[.init(seat: 0, rotation: 90)], [.init(seat: 1, rotation: 270)]])
    }

    @Test func landscapeFourFacesTopAndBottom() {
        let layout = TableLayout.layout(count: 4, landscape: true)
        #expect(layout.groups == [
            [.init(seat: 1, rotation: 180), .init(seat: 0, rotation: 0)],
            [.init(seat: 3, rotation: 180), .init(seat: 2, rotation: 0)],
        ])
    }

    @Test func facingsAreOnlyTouchedEdges() {
        let six = TableLayout.layout(count: 6, landscape: false)
        #expect(six.facings(seat: 0) == [.top, .left])
        #expect(six.facings(seat: 2) == [.left])
        #expect(six.facings(seat: 5) == [.bottom, .right])
        let two = TableLayout.layout(count: 2, landscape: false)
        #expect(two.facings(seat: 0) == [.top, .left, .right])
        let landscapeFour = TableLayout.layout(count: 4, landscape: true)
        #expect(landscapeFour.facings(seat: 1) == [.top, .left])
        #expect(landscapeFour.facings(seat: 2) == [.bottom, .right])
    }

    @Test(arguments: 2...6) func defaultFacingIsAlwaysAllowed(count: Int) {
        for landscape in [false, true] {
            let layout = TableLayout.layout(count: count, landscape: landscape)
            for seat in 0..<count {
                #expect(layout.facings(seat: seat).map(\.rotation).contains(layout.defaultRotation(seat: seat)))
            }
        }
    }

    @Test func glyphEdgeIsAwayFromTheControlSeam() {
        let six = TableLayout.layout(count: 6, landscape: false)
        #expect(six.glyphEdge(seat: 0) == .top)
        #expect(six.glyphEdge(seat: 2) == .bottom)
        let landscape = TableLayout.layout(count: 4, landscape: true)
        #expect(landscape.glyphEdge(seat: 0) == .left)
        #expect(landscape.glyphEdge(seat: 3) == .right)
        #expect(Facing.leadingEdge(rotation: 90) == .top)
        #expect(Facing.leadingEdge(rotation: 270) == .bottom)
    }

    @Test func defaultRotationLookup() {
        let layout = TableLayout.layout(count: 5, landscape: false)
        #expect(layout.defaultRotation(seat: 0) == 180)
        #expect(layout.defaultRotation(seat: 4) == 270)
    }
}
