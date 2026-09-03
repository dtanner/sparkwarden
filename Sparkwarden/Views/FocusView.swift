import SwiftUI

/// One commander seat filling the screen, facing the same way as its panel,
/// with room to adjust everything: life with its tap halves, commander
/// damage as one tile per commander at the table, then poison and commander
/// tax with buttons a thumb can't miss. The backdrop is the player's color
/// dimmed so a tile in that same color still stands out. Closes from the
/// corner button, a tap on the empty backdrop, or on its own after a pause
/// without counter changes — dimming further for the last moments so
/// nobody taps into the table underneath by surprise.
struct FocusView: View {
    @Environment(AppModel.self) private var model
    let seat: Int
    let defaultRotation: Int
    let facings: [Facing]
    let size: CGSize

    @State private var editingPlayer = false

    var body: some View {
        if let game = model.game, seat < game.count {
            let rotation = game.rotation(seat: seat, defaultRotation: defaultRotation)
            let quarter = rotation % 180 != 0
            let inner = quarter ? CGSize(width: size.height, height: size.width) : size
            content(player: game.players[seat], state: game[seat], inner: inner)
                .frame(width: inner.width, height: inner.height)
                .rotationEffect(.degrees(Double(rotation)))
                .frame(width: size.width, height: size.height)
                .sheet(isPresented: $editingPlayer) {
                    PlayerEditView(seat: seat, defaultRotation: defaultRotation, facings: facings)
                }
                // The idle close waits while the edit sheet is up.
                .onChange(of: editingPlayer) { _, editing in
                    if editing { model.holdFocus() } else { model.touchFocus() }
                }
        }
    }

    /// Life sits beside the tiles when the view is wider than tall and above
    /// them otherwise, so a seat facing a short edge gets a sensible stack.
    private func content(player: Player, state: PlayerState, inner: CGSize) -> some View {
        let fg = player.color.foreground
        let wide = inner.width >= inner.height
        let split = wide ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 12))
        return RoundedRectangle(cornerRadius: PlayerPanel.cornerRadius)
            .fill(player.color.color(lit: false))
            .overlay {
                RoundedRectangle(cornerRadius: PlayerPanel.cornerRadius)
                    .fill(.black.opacity(model.focusClosingSoon ? 0.6 : 0.3))
                    .animation(.easeInOut(duration: 0.5), value: model.focusClosingSoon)
            }
            .contentShape(RoundedRectangle(cornerRadius: PlayerPanel.cornerRadius))
            .onTapGesture { model.unfocus() }
            .overlay {
                VStack(spacing: 10) {
                    topBar(player: player, fg: fg)
                    split {
                        lifeBlock(player: player, state: state, fg: fg)
                            .frame(width: wide ? inner.width * 0.35 : nil,
                                   height: wide ? nil : inner.height * 0.3)
                        DamageTileGrid(seat: seat)
                            // A near miss between tiles does nothing rather than closing the view.
                            .contentShape(Rectangle())
                            .onTapGesture {}
                    }
                    FlowLayout(spacing: 12) {
                        CounterChip(systemImage: "cross.vial.fill", value: state.poison, large: true, fg: fg) { delta in
                            model.modify { $0.addPoison(delta, seat: seat) }
                        }
                        ForEach(0..<player.commanderCount, id: \.self) { commander in
                            CounterChip(systemImage: "crown.fill",
                                        badge: player.commanderCount > 1 ? "\(commander + 1).circle.fill" : nil,
                                        value: state.commanderTax[commander], step: 2, large: true, fg: fg) { delta in
                                model.modify { $0.addCommanderTax(delta, seat: seat, commander: commander) }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {}
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
            .foregroundStyle(fg)
    }

    private func topBar(player: Player, fg: Color) -> some View {
        HStack(spacing: 8) {
            Button { editingPlayer = true } label: {
                HStack(spacing: 4) {
                    Text(player.displayName).font(.headline).lineLimit(1)
                    Image(systemName: "ellipsis.circle").font(.subheadline)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(fg.opacity(0.2), in: Capsule())
            }
            Spacer(minLength: 8)
            Button { model.unfocus() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(fg.opacity(0.3), in: Circle())
            }
            .accessibilityLabel("Close")
        }
    }

    /// The seat's own panel, in its full color, so life works here exactly
    /// as it does at the table.
    private func lifeBlock(player: Player, state: PlayerState, fg: Color) -> some View {
        GeometryReader { geo in
            LifeControl(life: state.life, fg: fg, deltaLeading: true,
                        numberSize: min(geo.size.width, geo.size.height) * 0.42) { delta in
                model.modify { $0.addLife(delta, seat: seat) }
            }
        }
        .background(player.color.color(lit: false), in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Commander damage taken from every commander at the table, one tile per
/// commander painted in its owner's color, in whichever grid makes the
/// tiles largest. Each tile works like the life control — tap the top half
/// for +1, the bottom half for −1.
struct DamageTileGrid: View {
    @Environment(AppModel.self) private var model
    let seat: Int

    private static let spacing: CGFloat = 8

    var body: some View {
        if let game = model.game {
            let sources = game.damageSources(for: seat)
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
        }
    }

    /// The column count whose tiles come out largest, measured by the
    /// shorter side, so a wide area gets a row and a tall one a column.
    static func columns(count: Int, in size: CGSize) -> Int {
        guard count > 1 else { return 1 }
        func side(_ columns: Int) -> CGFloat {
            let rows = (count + columns - 1) / columns
            return min((size.width - Self.spacing * CGFloat(columns - 1)) / CGFloat(columns),
                       (size.height - Self.spacing * CGFloat(rows - 1)) / CGFloat(rows))
        }
        return (1...count).reduce(1) { side($1) > side($0) ? $1 : $0 }
    }
}

/// One commander's damage against this seat, in the commander owner's color.
/// Laid out like the life control: a faint + above the number and − below.
/// The seat's own commander gets a faint outline, since its tile is the one
/// color that matches the backdrop.
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
                VStack(spacing: 0) {
                    half(delta: 1, fg: fg)
                    half(delta: -1, fg: fg)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                // Small tiles skip the +/− hints; they'd crowd the number.
                let hints = side >= 80
                VStack(spacing: -side * 0.07) {
                    if hints { glyph("plus", fg: fg) }
                    Text("\(damage)")
                        .font(.system(size: min(side * 0.5, 72), weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: Double(damage)))
                        .animation(.snappy(duration: 0.15), value: damage)
                    if hints { glyph("minus", fg: fg) }
                }
                .allowsHitTesting(false)
                // Caption in one top corner, the running change in the other,
                // clear of the glyphs on the center line.
                HStack(alignment: .top) {
                    caption(named: geo.size.width >= 120)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .opacity(0.9)
                    Spacer(minLength: 4)
                    if pendingDelta != 0 {
                        Text(pendingDelta.formatted(.number.sign(strategy: .always())))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
            }
            .foregroundStyle(fg)
            .overlay {
                if damage >= PlayerState.commanderLethal {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(fg, lineWidth: 3)
                        .allowsHitTesting(false)
                } else if own {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(fg.opacity(0.35), lineWidth: 1.5)
                        .allowsHitTesting(false)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Commander damage from \(own ? "your own commander" : source.player.displayName)")
        .accessibilityValue("\(damage)")
    }

    private func glyph(_ name: String, fg: Color) -> some View {
        Image(systemName: name)
            .font(.headline.weight(.bold))
            .foregroundStyle(fg.opacity(0.4))
            .frame(height: 22)
    }

    /// The owner's name, numbered when they run two commanders. The color
    /// already says whose it is, so narrow tiles carry only the number.
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

    private func half(delta: Int, fg: Color) -> some View {
        Rectangle()
            .fill(fg.opacity(flashedDelta == delta ? 0.2 : 0))
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
