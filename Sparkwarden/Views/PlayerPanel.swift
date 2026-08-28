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
    /// Which half just got tapped, briefly lit to confirm the tap landed.
    @State private var flashedDelta = 0
    @State private var editingPlayer = false

    private static let gap: CGFloat = 3

    var body: some View {
        if let game = model.game, seat < game.count {
            let rotation = game.rotation(seat: seat, defaultRotation: defaultRotation)
            let quarter = rotation % 180 != 0
            let inner = quarter ? CGSize(width: size.height, height: size.width) : size
            panel(game: game, player: game.players[seat], state: game[seat], inner: inner, rotation: rotation)
                .frame(width: inner.width - Self.gap * 2, height: inner.height - Self.gap * 2)
                .rotationEffect(.degrees(Double(rotation)))
                .frame(width: size.width, height: size.height)
                .sheet(isPresented: $editingPlayer) {
                    PlayerEditView(seat: seat, defaultRotation: defaultRotation, facings: facings)
                }
        }
    }

    @ViewBuilder
    private func panel(game: Game, player: Player, state: PlayerState, inner: CGSize, rotation: Int) -> some View {
        let fg = player.color.foreground
        let lit = model.isLit(seat: seat)
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(player.color.color(lit: lit))
                .animation(.easeOut(duration: 0.12), value: lit)

            // Tap targets sit under the labels so the number itself is tappable.
            // Each half carries a faint glyph so the zones are discoverable,
            // and flashes when tapped.
            let glyphsLeading = Facing.leadingEdge(rotation: rotation) != glyphEdge.opposite
            VStack(spacing: 0) {
                tapZone(delta: 1, glyph: "plus", fg: fg, leading: glyphsLeading)
                tapZone(delta: -1, glyph: "minus", fg: fg, leading: glyphsLeading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(spacing: 0) {
                header(fg: fg)
                Spacer(minLength: 0)
                if showingCommander {
                    CommanderDamageList(seat: seat, fg: fg)
                } else {
                    lifeLabel(state: state, fg: fg, inner: inner)
                }
                Spacer(minLength: 0)
                counters(player: player, state: state, fg: fg)
            }
            .padding(10)

            if state.isDead {
                RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.55))
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
    /// otherwise the name gets its own line above the chips.
    @ViewBuilder
    private func counters(player: Player, state: PlayerState, fg: Color) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                nameButton(player)
                Spacer(minLength: 8)
                chips(state: state, fg: fg)
            }
            VStack(alignment: .leading, spacing: 6) {
                nameButton(player)
                chips(state: state, fg: fg)
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

    @ViewBuilder
    private func chips(state: PlayerState, fg: Color) -> some View {
        let game = model.game!
        HStack(spacing: 8) {
            CounterChip(systemImage: "cross.vial.fill", value: state.poison, fg: fg) { delta in
                model.modify { $0.addPoison(delta, seat: seat) }
            }
            if game.mode == .commander {
                CounterChip(systemImage: "crown.fill", value: state.commanderTax, step: 2, fg: fg) { delta in
                    model.modify { $0.addCommanderTax(delta, seat: seat) }
                }
                Button {
                    showingCommander.toggle()
                } label: {
                    Image(systemName: showingCommander ? "xmark" : "shield.lefthalf.filled")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, height: 30)
                        .background(fg.opacity(showingCommander ? 0.35 : 0.2), in: Capsule())
                }
            }
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
    let value: Int
    var step = 1
    let fg: Color
    let change: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            chipButton("minus") { change(-step) }
            HStack(spacing: 3) {
                Image(systemName: systemImage).font(.subheadline)
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

/// Commander damage taken from each opponent, shown in place of the life
/// number so it faces the same way as the rest of the panel.
struct CommanderDamageList: View {
    @Environment(AppModel.self) private var model
    let seat: Int
    let fg: Color

    var body: some View {
        if let game = model.game {
            ScrollView {
                VStack(spacing: 4) {
                    Text("Commander damage").font(.caption).opacity(0.8)
                    ForEach(game.opponents(of: seat), id: \.seat) { opponent in
                        let damage = game.commanderDamage(seat: seat, from: opponent.seat)
                        HStack {
                            Circle().fill(opponent.player.color.color(lit: false))
                                .frame(width: 10, height: 10)
                            Text(opponent.player.displayName).font(.subheadline).lineLimit(1)
                            Spacer(minLength: 4)
                            CounterChip(systemImage: "bolt.fill", value: damage, fg: fg) { delta in
                                model.modify { $0.addCommanderDamage(delta, seat: seat, from: opponent.seat) }
                            }
                        }
                        .opacity(damage >= PlayerState.commanderLethal ? 0.6 : 1)
                    }
                }
            }
        }
    }
}
