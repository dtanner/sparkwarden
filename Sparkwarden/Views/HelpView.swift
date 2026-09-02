import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("At the table") {
                    Text("Put the device in the middle of the table. Each player's panel faces their seat — players sit along the long sides, and with 2, 3, or 5 players one person sits at the top end.")
                    Text("Tap the + half of your panel for +1 life, the − half for −1. The running change shows above your total for a couple of seconds.")
                    Text("Poison is the vial counter. A panel dims when its player is out: 0 life, 10 poison, or 21 commander damage from one commander.")
                }
                Section("Center controls") {
                    Label("When a game starts, tap \"Who goes first?\" to spin a light around the table until it stops on the starter — or dismiss it if you already know.", systemImage: "sparkles")
                    Label("End the game (asks first) and return to setup.", systemImage: "xmark")
                }
                Section("Commander") {
                    Text("Commander mode starts at 40 life and adds a crown counter for commander tax (steps of 2) and a shield button for commander damage.")
                    Text("The shield turns your panel into one tile per commander at the table, each in its owner's color. Tap a tile's top half for +1 damage, its bottom half for −1. The panel goes back to your life total after a few seconds without a tap, or when you tap the dimmed area around the tiles.")
                    Text("Only combat damage counts. It also comes off your life, so don't tap it off your total as well. 21 from a single commander over the game is lethal, whoever controlled it at the time. A commander with infect deals its damage as poison instead; record it on the tile too, then put the life back.")
                    Text("Running partners? Turn on Two commanders from the ••• button. You get a second tax counter, marked ① and ②, and every panel tracks each of your commanders separately. Your own commander has a tile too, for when it gets stolen and turned on you.")
                }
                Section("Seats") {
                    Text("Names and colors are set on the setup screen and remembered for next time. Reset Names puts every seat back to “Player N”; colors are kept.")
                    Text("To match where people are sitting, long-press a panel and drop it on another: the two players trade places, counters included. Seating is remembered for the next game.")
                    Text("The ••• button on a panel renames or recolors that player, sets whether they run two commanders, or changes which edge of the screen the panel faces for odd table shapes. Facing belongs to the spot, not the player — it stays put through seat swaps and later games, until the day ends.")
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
