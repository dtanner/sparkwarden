import SwiftUI

/// A life total over its two tap halves: the top half adds one, the bottom
/// half takes one, and a swipe up or down anywhere on it adds or takes ten.
/// A faint + above the number and − below it mark the halves, each half
/// flashes when tapped, and the sum of the last burst of taps is reported
/// through `pendingDelta` for the owner to show where it fits, clearing
/// itself a few seconds after the last tap.
struct LifeControl: View {
    let life: Int
    let fg: Color
    let numberSize: CGFloat
    @Binding var pendingDelta: Int
    let change: (Int) -> Void

    /// How long the running change stays up after the last tap.
    static let linger: Duration = .seconds(4)
    /// Life changed by a swipe.
    static let swipeStep = 10
    /// How far a finger must travel to count as a swipe rather than a tap.
    static let swipeDistance: CGFloat = 40

    @State private var deltaResetTask: Task<Void, Never>?
    /// Which half just got tapped, briefly lit to confirm the tap landed.
    @State private var flashedDelta = 0

    var body: some View {
        VStack(spacing: 0) {
            tapZone(delta: 1)
            tapZone(delta: -1)
        }
        // A swipe starts moving at once, so it never competes with the long
        // press that drags a panel to swap seats. Sideways swipes do nothing.
        .gesture(DragGesture(minimumDistance: Self.swipeDistance).onEnded { drag in
            let dy = drag.translation.height
            guard abs(dy) > abs(drag.translation.width) else { return }
            tap(dy < 0 ? Self.swipeStep : -Self.swipeStep)
        })
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
        UIImpactFeedbackGenerator(style: abs(delta) > 1 ? .medium : .light).impactOccurred()
        flashedDelta = delta.signum()
        withAnimation(.easeOut(duration: 0.35)) { flashedDelta = 0 }
        withAnimation(.snappy(duration: 0.15)) { pendingDelta += delta }
        deltaResetTask?.cancel()
        deltaResetTask = Task {
            try? await Task.sleep(for: Self.linger)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { pendingDelta = 0 }
        }
    }
}

/// The running change from the last burst of life taps, big and bold,
/// shown while `delta` is nonzero. Never intercepts taps.
struct PendingDeltaLabel: View {
    let delta: Int
    let size: CGFloat

    var body: some View {
        if delta != 0 {
            Text(delta.formatted(.number.sign(strategy: .always())))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .opacity(0.9)
                .contentTransition(.numericText(value: Double(delta)))
                .transition(.opacity)
                .allowsHitTesting(false)
        }
    }
}
