import SwiftUI

/// One seat's block of color: tap the top half for +1 life, the bottom half
/// for −1, with poison (and commander counters) along the bottom edge.
/// Rotated to face its player; all controls rotate with it.
struct PlayerPanel: View {
    @Environment(AppModel.self) private var model
    let seat: Int
    let defaultRotation: Int
    let facings: [Facing]
    /// Screen edge to keep the +/− glyphs toward, away from the center controls.
    let glyphEdge: Facing
    let size: CGSize

    @State private var pendingDelta = 0
    @State private var deltaResetTask: Task<Void, Never>?
    @State private var showingCommander = false
    /// Closes the damage grid after a pause; while it's open the life
    /// number is hidden and the life tap zones are off.
    @State private var commanderCloseTask: Task<Void, Never>?
    /// Which half just got tapped, briefly lit to confirm the tap landed.
    @State private var flashedDelta = 0
    @State private var editingPlayer = false
    /// Another panel is being dragged over this one to swap seats.
    @State private var isDropTarget = false

    private static let gap: CGFloat = 3
    private static let commanderIdle: Duration = .seconds(8)
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
                // Every damage tap keeps the grid open a little longer.
                .onChange(of: game[seat].commanderDamage) { _, _ in
                    if showingCommander { showCommander(true) }
                }
        }
    }

    /// The background sets the panel's size; everything else is an overlay
    /// so content that doesn't fit spills rather than stretching the panel.
    @ViewBuilder
    private func panel(game: Game, player: Player, state: PlayerState, inner: CGSize, rotation: Int) -> some View {
        let fg = player.color.foreground
        let lit = model.isLit(seat: seat)
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(player.color.color(lit: lit))
            .animation(.easeOut(duration: 0.12), value: lit)
            .overlay {
                // Tap targets sit under the labels so the number itself is
                // tappable. Each half carries a faint glyph so the zones are
                // discoverable, and flashes when tapped.
                if !showingCommander {
                    let glyphsLeading = Facing.leadingEdge(rotation: rotation) != glyphEdge.opposite
                    VStack(spacing: 0) {
                        tapZone(delta: 1, glyph: "plus", fg: fg, leading: glyphsLeading)
                        tapZone(delta: -1, glyph: "minus", fg: fg, leading: glyphsLeading)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                }
            }
            .overlay {
                VStack(spacing: 0) {
                    header(fg: fg)
                    if showingCommander {
                        // The damage grid dims the panel so tiles in the
                        // player's own color still stand out.
                        CommanderDamageGrid(seat: seat, fg: fg) { showCommander(false) }
                            .padding(.top, 6)
                            .transition(.opacity)
                    } else {
                        Spacer(minLength: 0)
                        lifeLabel(state: state, fg: fg, inner: inner)
                        Spacer(minLength: 0)
                        counters(player: player, state: state, fg: fg)
                    }
                }
                .padding(10)
                .background {
                    // Tapping the dimmed panel around the tiles closes the grid.
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .fill(.black.opacity(showingCommander ? 0.35 : 0))
                        .contentShape(Rectangle())
                        .onTapGesture { showCommander(false) }
                        .allowsHitTesting(showingCommander)
                }
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

    private func tapZone(delta: Int, glyph: String, fg: Color, leading: Bool) -> some View {
        Rectangle()
            .fill(fg.opacity(flashedDelta == delta ? 0.18 : 0))
            // Glyphs hug the seam between the halves at whichever end is
            // farther from the center controls; neither the header nor the
            // counter chips reach there.
            .overlay(alignment: Alignment(horizontal: leading ? .leading : .trailing,
                                          vertical: delta > 0 ? .bottom : .top)) {
                Image(systemName: glyph)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(fg.opacity(0.3))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            }
            .contentShape(Rectangle())
            .onTapGesture { change(delta) }
    }

    /// The edge nearest the table center stays empty so the center controls
    /// never cover anything; only the "goes first" badge appears there.
    @ViewBuilder
    private func header(fg: Color) -> some View {
        if model.starterSeat == seat {
            Text("Goes first")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(fg.opacity(0.2), in: Capsule())
                .allowsHitTesting(false)
        } else {
            Text(" ").font(.subheadline)
        }
    }

    private func lifeLabel(state: PlayerState, fg: Color, inner: CGSize) -> some View {
        VStack(spacing: 0) {
            Text(pendingDelta == 0 ? " " : pendingDelta.formatted(.number.sign(strategy: .always())))
                .font(.title3.monospacedDigit().weight(.semibold))
                .opacity(0.85)
            Text("\(state.life)")
                .font(.system(size: min(inner.width, inner.height) * 0.42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(state.life)))
                .animation(.snappy(duration: 0.15), value: state.life)
        }
        .allowsHitTesting(false)
    }

    /// Name and counters share one row when the panel is wide enough;
    /// otherwise the name gets its own line and the chips wrap beneath it,
    /// as many per line as fit.
    @ViewBuilder
    private func counters(player: Player, state: PlayerState, fg: Color) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                nameButton(player)
                Spacer(minLength: 8)
                chips(player: player, state: state, fg: fg, layout: AnyLayout(HStackLayout(spacing: 8)))
            }
            VStack(alignment: .leading, spacing: 6) {
                nameButton(player)
                chips(player: player, state: state, fg: fg, layout: AnyLayout(FlowLayout(spacing: 6)))
            }
        }
    }

    private func nameButton(_ player: Player) -> some View {
        Button { editingPlayer = true } label: {
            HStack(spacing: 4) {
                Text(player.displayName).font(.headline).lineLimit(1).fixedSize()
                Image(systemName: "ellipsis.circle").font(.subheadline)
            }
        }
    }

    /// Poison, then in commander mode one tax chip per commander and the
    /// damage-grid button.
    @ViewBuilder
    private func chips(player: Player, state: PlayerState, fg: Color, layout: AnyLayout) -> some View {
        let game = model.game!
        layout {
            CounterChip(systemImage: "cross.vial.fill", value: state.poison, fg: fg) { delta in
                model.modify { $0.addPoison(delta, seat: seat) }
            }
            if game.mode == .commander {
                ForEach(0..<player.commanderCount, id: \.self) { commander in
                    CounterChip(systemImage: "crown.fill",
                                badge: player.commanderCount > 1 ? "\(commander + 1).circle.fill" : nil,
                                value: state.commanderTax[commander], step: 2, fg: fg) { delta in
                        model.modify { $0.addCommanderTax(delta, seat: seat, commander: commander) }
                    }
                }
                Button {
                    showCommander(true)
                } label: {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, height: 30)
                        .background(fg.opacity(0.2), in: Capsule())
                }
            }
        }
    }

    /// Opens (and re-arms the idle timer of) or closes the damage grid.
    private func showCommander(_ show: Bool) {
        withAnimation(.snappy(duration: 0.2)) { showingCommander = show }
        commanderCloseTask?.cancel()
        guard show else { return }
        commanderCloseTask = Task {
            try? await Task.sleep(for: Self.commanderIdle)
            guard !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.2)) { showingCommander = false }
        }
    }

    private func change(_ delta: Int) {
        model.modify { $0.addLife(delta, seat: seat) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        flashedDelta = delta
        withAnimation(.easeOut(duration: 0.35)) { flashedDelta = 0 }
        pendingDelta += delta
        deltaResetTask?.cancel()
        deltaResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            pendingDelta = 0
        }
    }
}

/// A small `− icon value +` pill that lives along the panel's bottom edge.
struct CounterChip: View {
    let systemImage: String
    /// A second, smaller symbol after the icon — the commander number on a
    /// partner player's tax chips.
    var badge: String? = nil
    let value: Int
    var step = 1
    let fg: Color
    let change: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            chipButton("minus") { change(-step) }
            HStack(spacing: 3) {
                Image(systemName: systemImage).font(.subheadline)
                if let badge { Image(systemName: badge).font(.caption2) }
                Text("\(value)").monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .frame(minWidth: 34)
            chipButton("plus") { change(step) }
        }
        .background(fg.opacity(0.2), in: Capsule())
    }

    private func chipButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.caption.weight(.bold))
                .frame(width: 30, height: 30)
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

/// Commander damage taken from every commander at the table, one tile per
/// commander painted in its owner's color. Takes over the panel so the tiles
/// get all the room; each works like the panel itself — tap the top half
/// for +1, the bottom half for −1. Life stays visible in the footer since
/// commander damage comes off it too. The panel closes the grid again after
/// a pause without taps.
struct CommanderDamageGrid: View {
    @Environment(AppModel.self) private var model
    let seat: Int
    let fg: Color
    let close: () -> Void

    private static let spacing: CGFloat = 6

    var body: some View {
        if let game = model.game {
            let sources = game.damageSources(for: seat)
            VStack(spacing: 8) {
                GeometryReader { geo in
                    let columns = Self.columns(count: sources.count, in: geo.size)
                    VStack(spacing: Self.spacing) {
                        ForEach(Array(stride(from: 0, to: sources.count, by: columns)), id: \.self) { start in
                            let row = sources[start..<min(start + columns, sources.count)]
                            HStack(spacing: Self.spacing) {
                                ForEach(row) { source in
                                    DamageTile(source: source,
                                               own: source.seat == seat,
                                               damage: game.commanderDamage(seat: seat, from: source)) { delta in
                                        model.modify { $0.addCommanderDamage(delta, seat: seat, from: source) }
                                    }
                                }
                                // Fillers keep a short last row's tiles the same size as the rest.
                                ForEach(row.count..<columns, id: \.self) { _ in
                                    Color.clear.allowsHitTesting(false)
                                }
                            }
                        }
                    }
                }
                footer(life: game[seat].life)
            }
        }
    }

    /// The column count whose tiles come out largest, measured by the
    /// shorter side, so a wide panel gets a row and a tall one a column.
    static func columns(count: Int, in size: CGSize) -> Int {
        guard count > 1 else { return 1 }
        func side(_ columns: Int) -> CGFloat {
            let rows = (count + columns - 1) / columns
            return min((size.width - Self.spacing * CGFloat(columns - 1)) / CGFloat(columns),
                       (size.height - Self.spacing * CGFloat(rows - 1)) / CGFloat(rows))
        }
        return (1...count).reduce(1) { side($1) > side($0) ? $1 : $0 }
    }

    private func footer(life: Int) -> some View {
        HStack(spacing: 8) {
            ViewThatFits(in: .horizontal) {
                Label("Commander damage", systemImage: "shield.lefthalf.filled").lineLimit(1).fixedSize()
                Image(systemName: "shield.lefthalf.filled")
            }
            .font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            HStack(spacing: 3) {
                Image(systemName: "heart.fill").font(.subheadline)
                Text("\(life)").monospacedDigit()
                    .contentTransition(.numericText(value: Double(life)))
                    .animation(.snappy(duration: 0.15), value: life)
            }
            .font(.headline)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 30, height: 30)
                    .background(fg.opacity(0.35), in: Capsule())
            }
            .accessibilityLabel("Close commander damage")
        }
    }
}

/// One commander's damage against this seat, in the commander owner's color.
private struct DamageTile: View {
    let source: Game.Commander
    /// This is the seat's own commander.
    let own: Bool
    let damage: Int
    let change: (Int) -> Void

    @State private var flashedDelta = 0
    /// Sum of the last burst of taps, shown briefly so a run of +1s can be checked.
    @State private var pendingDelta = 0
    @State private var pendingResetTask: Task<Void, Never>?

    var body: some View {
        let color = source.player.color
        let fg = color.foreground
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.color(lit: false))
                // Small tiles skip the +/− hints; they'd crowd the number.
                let hints = side >= 80
                VStack(spacing: 0) {
                    half(delta: 1, glyph: hints ? "plus" : nil, fg: fg)
                    half(delta: -1, glyph: hints ? "minus" : nil, fg: fg)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text("\(damage)")
                        .font(.system(size: min(side * 0.55, 64), weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: Double(damage)))
                        .animation(.snappy(duration: 0.15), value: damage)
                    Spacer(minLength: 0)
                    caption(named: hints)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .opacity(0.85)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 3)
                }
                .allowsHitTesting(false)
                if pendingDelta != 0 {
                    Text(pendingDelta.formatted(.number.sign(strategy: .always())))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .allowsHitTesting(false)
                }
            }
            .foregroundStyle(fg)
            .overlay {
                if damage >= PlayerState.commanderLethal {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(fg, lineWidth: 3)
                        .allowsHitTesting(false)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Commander damage from \(own ? "your own commander" : source.player.displayName)")
        .accessibilityValue("\(damage)")
    }

    /// The owner's name, numbered when they run two commanders. The color
    /// already says whose it is, so small tiles carry only the number.
    @ViewBuilder
    private func caption(named: Bool) -> some View {
        let badge = source.player.commanderCount > 1
            ? Image(systemName: "\(source.index + 1).circle.fill") : nil
        if named {
            HStack(spacing: 2) {
                Text(own ? "You" : source.player.displayName)
                badge
            }
        } else {
            badge
        }
    }

    private func half(delta: Int, glyph: String?, fg: Color) -> some View {
        Rectangle()
            .fill(fg.opacity(flashedDelta == delta ? 0.2 : 0))
            .overlay(alignment: delta > 0 ? .bottomLeading : .topLeading) {
                if let glyph {
                    Image(systemName: glyph)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(fg.opacity(0.35))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                change(delta)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                flashedDelta = delta
                withAnimation(.easeOut(duration: 0.35)) { flashedDelta = 0 }
                pendingDelta += delta
                pendingResetTask?.cancel()
                pendingResetTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    pendingDelta = 0
                }
            }
    }
}
