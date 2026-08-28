import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.game != nil {
            GameView()
        } else {
            SetupView()
        }
    }
}
