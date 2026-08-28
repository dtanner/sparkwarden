import SwiftUI

@main
struct SparkwardenApp: App {
    @State private var model = {
        let model = AppModel()
        // `--start-game` jumps straight to the table for screenshots.
        if ProcessInfo.processInfo.arguments.contains("--start-game") { model.startGame() }
        return model
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .preferredColorScheme(.dark)
        }
    }
}
