import SwiftUI

/// Rename, recolor, or rotate one seat mid-game.
struct PlayerEditView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let seat: Int
    let defaultRotation: Int
    /// Edges this panel touches; anything else would face into the table.
    let facings: [Facing]

    var body: some View {
        NavigationStack {
            Form {
                if let game = model.game, seat < game.count {
                    let binding = Binding(
                        get: { game.players[seat] },
                        set: { model.update($0, seat: seat) }
                    )
                    Section("Player") { PlayerRow(player: binding) }
                    if game.mode == .commander {
                        Section {
                            Toggle("Two commanders", isOn: Binding(
                                get: { binding.wrappedValue.commanderCount > 1 },
                                set: { binding.wrappedValue.commanderCount = $0 ? Player.maxCommanders : 1 }
                            ))
                        } footer: {
                            Text("For partners and other pairs. Each commander's damage is tracked separately on every panel.")
                        }
                    }
                    if facings.count > 1 {
                    Section {
                        Picker("Faces", selection: Binding(
                            get: { game.rotation(seat: seat, defaultRotation: defaultRotation) },
                            set: { degrees in model.setRotation(degrees, seat: seat) }
                        )) {
                            ForEach(facings) { facing in
                                Label(facing.label, systemImage: facing.systemImage).tag(facing.rotation)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } header: {
                        Text("Panel faces")
                    } footer: {
                        Text("Which edge of the screen this player sits at. Change it if the seat isn't where the layout expects.")
                    }
                    }
                }
            }
            .navigationTitle("Seat \(seat + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
