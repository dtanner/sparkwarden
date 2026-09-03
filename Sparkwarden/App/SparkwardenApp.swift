import SwiftUI

@main
struct SparkwardenApp: App {
    @State private var model = {
        let model = AppModel()
        // `--start-game` jumps straight to the table for screenshots, and
        // `--focus-seat N` then opens that seat's focus view.
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--start-game") { model.startGame() }
        if let i = arguments.firstIndex(of: "--focus-seat"), let seat = arguments.dropFirst(i + 1).first.flatMap(Int.init) {
            model.focus(seat: seat)
        }
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
