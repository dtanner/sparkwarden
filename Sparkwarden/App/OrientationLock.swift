import SwiftUI

/// Holds the screen still while a game is running. The device lies flat in
/// the middle of the table, and any reorientation when someone bumps it —
/// including the 180° flip between the two landscape directions, which swaps
/// the seats' sides — only disorients players. Setup and Help rotate freely.
///
/// Two mechanisms cover the two OS generations. The app-delegate mask is what
/// iOS 17–25 honor (on iPad only because the app requires full screen).
/// iPadOS 26 is retiring that route in favor of `GameHostingController`'s
/// per-view-controller preference, which the system grants only while the
/// scene fills the screen and drops on its own in a window or Split View.
@MainActor
final class OrientationLock: NSObject, UIApplicationDelegate {
    private static var allowed: UIInterfaceOrientationMask = .all
    /// What the screen showed before the lock, to return to afterwards when
    /// the device's physical orientation isn't known.
    private static var beforeLock: UIInterfaceOrientationMask?

    /// Freezes the app in the orientation it's showing now. An iPhone in
    /// portrait turns to landscape first, since the table is landscape-only
    /// there; an iPad table works tall or wide, so it keeps whatever it has.
    static func lockToCurrent() {
        let current = windowScenes.first.flatMap { UIInterfaceOrientationMask($0.effectiveGeometry.interfaceOrientation) }
        beforeLock = current
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if let current, isPad || current.isSubset(of: .landscape) {
            apply(current)
        } else {
            apply(.landscapeRight)
        }
    }

    /// Allows every orientation again and turns the screen back to match how
    /// the device is being held, since the lock may have left the two
    /// disagreeing. Without a reading (the simulator never gives one), the
    /// pre-lock orientation is the best guess.
    static func unlock() {
        apply(.all)
        if let target = heldOrientation ?? beforeLock {
            for scene in windowScenes {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: target))
            }
        }
    }

    /// The interface orientation matching the device's physical orientation,
    /// or nil when it's face up, face down, or unknown.
    private static var heldOrientation: UIInterfaceOrientationMask? {
        switch UIDevice.current.orientation {
        case .portrait: .portrait
        case .portraitUpsideDown where UIDevice.current.userInterfaceIdiom == .pad: .portraitUpsideDown
        // Device and interface landscapes are named from opposite viewpoints.
        case .landscapeLeft: .landscapeRight
        case .landscapeRight: .landscapeLeft
        default: nil
        }
    }

    private static func apply(_ mask: UIInterfaceOrientationMask) {
        allowed = mask
        for scene in windowScenes {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
            scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    private static var windowScenes: [UIWindowScene] {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // `UIDevice.orientation` only reports while notifications are on.
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.allowed
    }
}

private extension UIInterfaceOrientationMask {
    init?(_ orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

/// Wraps the table in a view controller so it can state the iOS 26
/// orientation-lock preference. Modifiers that reach the root view controller
/// (status bar, home indicator) don't cross this boundary, so `ContentView`
/// applies them outside.
struct GameHost: UIViewControllerRepresentable {
    let model: AppModel

    func makeUIViewController(context: Context) -> GameHostingController {
        GameHostingController(rootView: AnyView(GameView().environment(model)))
    }

    func updateUIViewController(_ controller: GameHostingController, context: Context) {}
}

final class GameHostingController: UIHostingController<AnyView> {
    @available(iOS 26.0, *)
    override var prefersInterfaceOrientationLocked: Bool { true }

    /// The system reads the lock preference through the parent, which has to
    /// be told when the child that answered it is leaving, or iOS 26 keeps
    /// the lock after the game ends.
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if #available(iOS 26, *), parent == nil {
            self.parent?.setNeedsUpdateOfPrefersInterfaceOrientationLocked()
        }
    }
}
