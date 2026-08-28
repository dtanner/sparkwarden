import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("At the table") {
                    Text("Put the device in the middle of the table. Each player's panel faces their seat — players sit along the long sides, and with 2, 3, or 5 players one person sits at the top end.")
                    Text("Tap the + half of your panel for +1 life, the − half for −1. The running change shows above your total for a couple of seconds.")
                    Text("Poison is the vial counter. A panel dims when its player is out: 0 life, 10 poison, or 21 commander damage from one opponent.")
                }
                Section("Center controls") {
                    Label("When a game starts, tap \"Who goes first?\" to spin a light around the table until it stops on the starter — or dismiss it if you already know.", systemImage: "sparkles")
                    Label("End the game (asks first) and return to setup.", systemImage: "xmark")
                }
                Section("Commander") {
                    Text("Commander mode starts at 40 life and adds a crown counter for commander tax (steps of 2) and a shield button that tracks damage taken from each opponent's commander. Commander damage also comes off life.")
                }
                Section("Seats") {
                    Text("Names and colors are set on the setup screen and remembered for next time. Once players have names, drag the seats into the order people are sitting. Reset Names puts every seat back to “Player N”; colors are kept.")
                    Text("The ••• button on a panel renames or recolors that player, or changes which edge of the screen the panel faces for odd table shapes.")
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
