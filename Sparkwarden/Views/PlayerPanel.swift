import SwiftUI

/// One seat's block of color: tap the top half for +1 life, the bottom half
/// for −1, the full height of the panel. Everything else sits in a column
/// down the side farther from the center controls, out of the tap zones: in
/// casual the name and the poison counter; in commander one button that
/// opens the seat's focus view, where everything but life is adjusted.
/// Rotated to face its player; all controls rotate with it.
struct PlayerPanel: View {
    @Environment(AppModel.self) private var model
    let seat: Int
    let defaultRotation: Int
    let facings: [Facing]
    /// Screen edge to keep the side column and floating labels toward, away
    /// from the center controls.
    let outerEdge: Facing
    let size: CGSize

    @State private var editingPlayer = false
    /// Another panel is being dragged over this one to swap seats.
    @State private var isDropTarget = false

    private static let gap: CGFloat = 3
    static let cornerRadius: CGFloat = 18

    var body: some View {
        if let game = model.game, seat < game.count {
            let rotation = game.rotation(seat: seat, defaultRotation: defaultRotation)
            let quarter = rotation % 180 != 0
            let inner = quarter ? CGSize(width: size.height, height: size.width) : size
            panel(game: game, player: game.players[seat], state: game[seat], inner: inner, rotation: rotation)
                .frame(width: inner.width - Self.gap * 2, height: inner.height - Self.gap * 2)
                .rotationEffect(.degrees(Double(rotation)))
                .frame(width: size.width, height: size.height)
                // Long-press and drop on another panel to trade seats.
                .draggable(String(seat))
                .dropDestination(for: String.self) { items, _ in
                    guard let other = items.first.flatMap(Int.init), other != seat else { return false }
                    model.swapSeats(seat, other)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    return true
                } isTargeted: { isDropTarget = $0 }
                .overlay {
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .strokeBorder(.white, lineWidth: isDropTarget ? 4 : 0)
                        .padding(Self.gap)
                        .animation(.easeOut(duration: 0.15), value: isDropTarget)
                        .allowsHitTesting(false)
                }
                .sheet(isPresented: $editingPlayer) {
                    PlayerEditView(seat: seat, defaultRotation: defaultRotation, facings: facings)
                }
        }
    }

    /// The background sets the panel's size; everything else is an overlay
    /// so content that doesn't fit spills rather than stretching the panel.
    @ViewBuilder
    private func panel(game: Game, player: Player, state: PlayerState, inner: CGSize, rotation: Int) -> some View {
        let fg = player.color.foreground
        let lit = model.isLit(seat: seat)
        // The column, the running change, and the "goes first" badge (the
        // last two never shown at the same time) all keep to the side of the
        // panel farther from the center controls. When the controls sit
        // along the panel's top instead, the column's contents gather at
        // its bottom.
        let outerLeading = Facing.leadingEdge(rotation: rotation) != outerEdge.opposite
        let seamAtTop = Facing.topEdge(rotation: rotation) == outerEdge.opposite
        let column = Group {
            if game.mode == .commander {
                focusColumn(game: game, player: player, state: state, fg: fg)
            } else {
                casualColumn(player: player, state: state, fg: fg, gatherAtBottom: seamAtTop)
            }
        }
        .frame(maxWidth: inner.width * 0.4, maxHeight: .infinity, alignment: seamAtTop ? .bottom : .top)
        .layoutPriority(1)
        .padding(outerLeading ? .leading : .trailing, 10)
        .padding(.vertical, 10)
        let life = LifeControl(life: state.life, fg: fg, deltaLeading: outerLeading,
                               numberSize: min(inner.width, inner.height) * 0.42) { delta in
            model.modify { $0.addLife(delta, seat: seat) }
        }
        .overlay(alignment: outerLeading ? .topLeading : .topTrailing) {
            starterBadge(fg: fg).padding(10)
        }
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(player.color.color(lit: lit))
            .animation(.easeOut(duration: 0.12), value: lit)
            .overlay {
                HStack(spacing: 0) {
                    if outerLeading {
                        column
                        life
                    } else {
                        life
                        column
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
            }
            .overlay {
                if state.isDead {
                    RoundedRectangle(cornerRadius: Self.cornerRadius).fill(.black.opacity(0.55))
                        .allowsHitTesting(false)
                    Image(systemName: "xmark.circle")
                        .font(.system(size: min(inner.width, inner.height) * 0.3))
                        .foregroundStyle(.white.opacity(0.7))
                        .allowsHitTesting(false)
                }
            }
            .foregroundStyle(fg)
    }

    /// Taps pass through the badge to the life control.
    @ViewBuilder
    private func starterBadge(fg: Color) -> some View {
        if model.starterSeat == seat {
            Text("Goes first")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(fg.opacity(0.2), in: Capsule())
                .allowsHitTesting(false)
        }
    }

    /// Casual: the name at the top of the column and poison at the bottom —
    /// or both gathered at the bottom when the center controls run along
    /// the panel's top.
    private func casualColumn(player: Player, state: PlayerState, fg: Color, gatherAtBottom: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if gatherAtBottom {
                Spacer(minLength: 0)
            } else {
                nameButton(player)
                Spacer(minLength: 0)
            }
            CounterChip(systemImage: "cross.vial.fill", value: state.poison, fg: fg) { delta in
                model.modify { $0.addPoison(delta, seat: seat) }
            }
            if gatherAtBottom { nameButton(player) }
        }
    }

    private func nameButton(_ player: Player) -> some View {
        Button { editingPlayer = true } label: {
            HStack(spacing: 4) {
                Text(player.displayName).font(.headline).lineLimit(1)
                Image(systemName: "ellipsis.circle").font(.subheadline)
            }
        }
    }

    /// Commander: the panel's one button, no bigger than its contents so the
    /// life total stays the panel's main event. Shows the name and whatever
    /// counters are nonzero — poison, tax per commander, and damage taken as
    /// a swatch in the attacker's color — and opens the focus view.
    private func focusColumn(game: Game, player: Player, state: PlayerState, fg: Color) -> some View {
        let sources = game.damageSources(for: seat)
        let hasCounters = state.poison > 0
            || (0..<player.commanderCount).contains { state.commanderTax[$0] > 0 }
            || sources.contains { game.commanderDamage(seat: seat, from: $0) > 0 }
        return Button { model.focus(seat: seat) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(player.displayName).font(.headline).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(fg.opacity(0.25), in: Circle())
                }
                if hasCounters {
                    FlowLayout(spacing: 4) {
                        if state.poison > 0 {
                            StatusBadge(fg: fg) {
                                Image(systemName: "cross.vial.fill")
                                Text("\(state.poison)")
                            }
                        }
                        ForEach(0..<player.commanderCount, id: \.self) { commander in
                            if state.commanderTax[commander] > 0 {
                                StatusBadge(fg: fg) {
                                    Image(systemName: "crown.fill")
                                    if player.commanderCount > 1 {
                                        Image(systemName: "\(commander + 1).circle.fill").font(.caption2)
                                    }
                                    Text("\(state.commanderTax[commander])")
                                }
                            }
                        }
                        ForEach(sources) { source in
                            let damage = game.commanderDamage(seat: seat, from: source)
                            if damage > 0 {
                                DamageBadge(source: source, damage: damage)
                            }
                        }
                    }
                }
            }
            .padding(8)
            .background(fg.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("\(player.displayName)'s counters")
    }
}

/// A read-only counter on the commander panel's button.
private struct StatusBadge<Content: View>: View {
    let fg: Color
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 4) { content }
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(fg.opacity(0.18), in: Capsule())
    }
}

/// Damage taken from one commander: a swatch in its owner's color, numbered
/// when the owner runs two, and the total.
private struct DamageBadge: View {
    let source: Game.Commander
    let damage: Int

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4)
                .fill(source.player.color.color(lit: false))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.35)))
                .frame(width: 16, height: 16)
            if source.player.commanderCount > 1 {
                Image(systemName: "\(source.index + 1).circle.fill").font(.caption2)
            }
            Text("\(damage)")
        }
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(.black.opacity(0.22), in: Capsule())
    }
}

/// A `− icon value +` pill: small in a panel's side column, large in the focus view.
struct CounterChip: View {
    let systemImage: String
    /// A second, smaller symbol after the icon — the commander number on a
    /// partner player's tax chips.
    var badge: String? = nil
    let value: Int
    var step = 1
    /// Focus-view size: taller, with buttons well past the 44pt minimum.
    var large = false
    let fg: Color
    let change: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            chipButton("minus") { change(-step) }
            HStack(spacing: 3) {
                Image(systemName: systemImage).font(large ? .title3 : .subheadline)
                if let badge { Image(systemName: badge).font(large ? .caption : .caption2) }
                Text("\(value)").monospacedDigit()
            }
            .font((large ? Font.title3 : .subheadline).weight(.semibold))
            .frame(minWidth: large ? 64 : 34)
            chipButton("plus") { change(step) }
        }
        .background(fg.opacity(0.2), in: Capsule())
    }

    private func chipButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font((large ? Font.headline : .caption).weight(.bold))
                .frame(width: large ? 60 : 30, height: large ? 48 : 30)
                .contentShape(Rectangle())
        }
    }
}

/// Lays its children out left to right, starting a new line when the next
/// one wouldn't fit. Lines are as tall as their tallest child.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = lines(fitting: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: lines.map(\.width).max() ?? 0,
                      height: lines.map(\.height).reduce(0, +) + spacing * CGFloat(max(lines.count - 1, 0)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(fitting: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                                      proposal: .unspecified)
                x += size.width + spacing
            }
            y += line.height + spacing
        }
    }

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(fitting maxWidth: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = line.indices.isEmpty ? size.width : line.width + spacing + size.width
            if !line.indices.isEmpty && needed > maxWidth {
                lines.append(line)
                line = Line()
            }
            line.indices.append(index)
            line.width = line.indices.count == 1 ? size.width : line.width + spacing + size.width
            line.height = max(line.height, size.height)
        }
        lines.append(line)
        return lines
    }
}
