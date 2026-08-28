import SwiftUI

/// The table: every seat's panel arranged so it faces its player, with the
/// shared controls (starter roulette, seats, end game) floating in the center.
struct GameView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmingEnd = false

    var body: some View {
        GeometryReader { geo in
            let layout = TableLayout.layout(count: model.game?.count ?? 0,
                                            landscape: geo.size.width > geo.size.height)
            // Controls sit on the seam between the first two rows (or columns
            // in landscape) — the screen center for even counts, and never on
            // top of a panel's number when there are three.
            let seam = 1 / CGFloat(max(layout.groups.count, 1))
            ZStack {
                TableView(layout: layout, size: geo.size)
                centerControls
                    .position(x: layout.isLandscape ? geo.size.width * seam : geo.size.width / 2,
                              y: layout.isLandscape ? geo.size.height / 2 : geo.size.height * seam)
            }
        }
        .padding(4)
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .confirmationDialog("End this game?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End Game", role: .destructive) { model.endGame() }
        } message: {
            Text("All life totals and counters will be reset.")
        }
    }

    /// At game start: "who goes first?" with spin and dismiss. Once the game
    /// is under way only the end-game button remains.
    private var centerControls: some View {
        HStack(spacing: 10) {
            if model.showsStarterPrompt {
                Button { model.spinForStarter() } label: {
                    Label("Who goes first?", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.white.opacity(0.15), in: Capsule())
                }
                .foregroundStyle(.white)
                .disabled(model.isSpinning)
                CenterButton(systemImage: "xmark", disabled: model.isSpinning) { model.dismissStarterPrompt() }
            } else {
                CenterButton(systemImage: "xmark", disabled: false) { confirmingEnd = true }
                    .accessibilityLabel("End game")
            }
        }
        .padding(6)
        .background(.black.opacity(0.85), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.2)))
        .animation(.snappy, value: model.showsStarterPrompt)
    }
}

private struct CenterButton: View {
    let systemImage: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.12), in: Circle())
        }
        .foregroundStyle(.white)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}

/// Lays the panels out per `layout`, giving every panel an equal share.
struct TableView: View {
    let layout: TableLayout
    let size: CGSize

    var body: some View {
        let groupCount = CGFloat(layout.groups.count)
        if layout.isLandscape {
            HStack(spacing: 0) {
                ForEach(Array(layout.groups.enumerated()), id: \.offset) { _, column in
                    let w = size.width / groupCount
                    VStack(spacing: 0) {
                        ForEach(column, id: \.seat) { slot in
                            PlayerPanel(seat: slot.seat, defaultRotation: slot.rotation,
                                        facings: layout.facings(seat: slot.seat),
                                        glyphEdge: layout.glyphEdge(seat: slot.seat),
                                        size: CGSize(width: w, height: size.height / CGFloat(column.count)))
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(layout.groups.enumerated()), id: \.offset) { _, row in
                    let h = size.height / groupCount
                    HStack(spacing: 0) {
                        ForEach(row, id: \.seat) { slot in
                            PlayerPanel(seat: slot.seat, defaultRotation: slot.rotation,
                                        facings: layout.facings(seat: slot.seat),
                                        glyphEdge: layout.glyphEdge(seat: slot.seat),
                                        size: CGSize(width: size.width / CGFloat(row.count), height: h))
                        }
                    }
                }
            }
        }
    }
}
