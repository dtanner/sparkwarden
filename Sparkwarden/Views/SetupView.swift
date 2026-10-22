import SwiftUI

/// Pre-game screen: mode, starting life, how many seats, and who sits where.
struct SetupView: View {
    @Environment(AppModel.self) private var model
    @State private var showingHelp = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("Game") {
                    Picker("Mode", selection: $model.settings.mode) {
                        ForEach(GameMode.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: model.settings.mode) { _, mode in
                        model.settings.startingLife = mode.defaultStartingLife
                    }
                    Stepper(value: $model.settings.startingLife, in: GameSettings.lifeRange) {
                        HStack {
                            Text("Starting life")
                            Spacer()
                            Text("\(model.settings.startingLife)").monospacedDigit().bold()
                        }
                    }
                    HStack {
                        ForEach([20, 25, 30, 40], id: \.self) { life in
                            Button("\(life)") { model.settings.startingLife = life }
                                .buttonStyle(.bordered)
                                .tint(model.settings.startingLife == life ? .accentColor : .secondary)
                        }
                    }
                    Stepper(value: $model.settings.playerCount,
                            in: GameSettings.minPlayers...GameSettings.maxPlayers) {
                        HStack {
                            Text("Players")
                            Spacer()
                            Text("\(model.settings.playerCount)").monospacedDigit().bold()
                        }
                    }
                }
                Section {
                    NavigationLink {
                        ThemePicker(theme: $model.settings.theme,
                                    colors: model.settings.seated.map(\.color))
                    } label: {
                        LabeledContent("Theme", value: model.settings.theme.label)
                    }
                }
                Section {
                    ForEach($model.settings.players.prefix(model.settings.playerCount)) { $player in
                        PlayerRow(player: $player)
                    }
                } header: {
                    Text("Players")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who's playing. At the table, long-press a panel and drop it on another to trade seats.")
                        if model.settings.hasCustomNames {
                            Button("Reset Names", role: .destructive) { model.settings.resetNames() }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    model.startGame()
                } label: {
                    Text("Start Game")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("Sparkwarden")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingHelp = true } label: { Image(systemName: "questionmark.circle") }
                }
            }
            .sheet(isPresented: $showingHelp) { HelpView() }
        }
    }
}

/// One seat in the roster: name text field plus a color swatch menu.
struct PlayerRow: View {
    @Environment(\.colorTheme) private var theme
    @Binding var player: Player

    var body: some View {
        HStack {
            Menu {
                ForEach(PlayerColor.allCases) { color in
                    Button {
                        player.color = color
                    } label: {
                        Label {
                            Text(theme.swatch(color).name)
                        } icon: {
                            Image(uiImage: color.swatch(in: theme, selected: player.color == color))
                        }
                    }
                }
            } label: {
                Circle()
                    .fill(theme.fill(player.color, lit: false))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(.white.opacity(0.3)))
            }
            TextField("Name", text: $player.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            Image(systemName: "pencil").foregroundStyle(.tertiary)
        }
    }
}

/// Every theme, each previewed with the seated players' colors on its backdrop.
struct ThemePicker: View {
    @Binding var theme: ColorTheme
    let colors: [PlayerColor]

    var body: some View {
        List(ColorTheme.allCases) { option in
            Button {
                theme = option
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.label).font(.headline)
                            Text(option.summary).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if option == theme {
                            Image(systemName: "checkmark").font(.headline).foregroundStyle(.tint)
                        }
                    }
                    HStack(spacing: 4) {
                        ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(option.fill(color, lit: false))
                                .overlay(Text("20").font(.headline.monospacedDigit())
                                    .foregroundStyle(option.foreground(color)))
                                .frame(height: 44)
                        }
                    }
                    .padding(4)
                    .background(option.backdrop, in: RoundedRectangle(cornerRadius: 11))
                }
                .padding(.vertical, 4)
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PlayerColor {
    /// Menu items draw their icons as template images, which would flatten
    /// every swatch to white; a pre-rendered original-mode image keeps the color.
    func swatch(in theme: ColorTheme, selected: Bool) -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(theme.fill(self, lit: false)).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            if selected {
                let check = UIImage(systemName: "checkmark", withConfiguration:
                    UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))!
                    .withTintColor(UIColor(theme.foreground(self)), renderingMode: .alwaysOriginal)
                let r = CGRect(x: (size.width - check.size.width) / 2,
                               y: (size.height - check.size.height) / 2,
                               width: check.size.width, height: check.size.height)
                check.draw(in: r)
            }
        }
        return image.withRenderingMode(.alwaysOriginal)
    }
}
