import SwiftUI

/// A life total over its two tap halves: the top half adds one, the bottom
/// half takes one. A faint + above the number and − below it mark the
/// halves, each half flashes when tapped, and the sum of the last burst of
/// taps shows in a top corner for a moment so a run of +1s can be checked.
struct LifeControl: View {
    let life: Int
    let fg: Color
    /// Which top corner the running change sits in — the one clear of the
    /// table's center controls.
    let deltaLeading: Bool
    let numberSize: CGFloat
    let change: (Int) -> Void

    @State private var pendingDelta = 0
    @State private var deltaResetTask: Task<Void, Never>?
    /// Which half just got tapped, briefly lit to confirm the tap landed.
    @State private var flashedDelta = 0

    var body: some View {
        VStack(spacing: 0) {
            tapZone(delta: 1)
            tapZone(delta: -1)
        }
        .overlay {
            // The rounded font's line box is much taller than its digits, so
            // the glyphs overlap it to sit just off the top and bottom of them.
            VStack(spacing: -numberSize * 0.16) {
                glyph("plus")
                Text("\(life)")
                    .font(.system(size: numberSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .contentTransition(.numericText(value: Double(life)))
                    .animation(.snappy(duration: 0.15), value: life)
                glyph("minus")
            }
            .padding(.horizontal, 12)
            .allowsHitTesting(false)
        }
        .overlay(alignment: deltaLeading ? .topLeading : .topTrailing) {
            if pendingDelta != 0 {
                Text(pendingDelta.formatted(.number.sign(strategy: .always())))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .opacity(0.85)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .allowsHitTesting(false)
            }
        }
    }

    private func glyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.title2.weight(.bold))
            .foregroundStyle(fg.opacity(0.4))
            .frame(height: 30)
    }

    private func tapZone(delta: Int) -> some View {
        Rectangle()
            .fill(fg.opacity(flashedDelta == delta ? 0.18 : 0))
            .contentShape(Rectangle())
            .onTapGesture { tap(delta) }
    }

    private func tap(_ delta: Int) {
        change(delta)
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
