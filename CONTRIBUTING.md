# Contributing to Sparkwarden

## Architecture

- **`AppModel`** (`@MainActor`, `@Observable`) is the single source of app
  state: persisted `GameSettings` (UserDefaults, JSON), the `Game` in
  progress, and the starter-roulette animation state.
- **Services** (`Sparkwarden/Services/`) hold the testable rules as pure value
  types: `Game` (life, poison, commander counters, death, facing),
  `TableLayout` (where each seat's panel goes and which way it faces), and
  `StarterRoulette` (the decelerating light sequence).
- **Views** (`Sparkwarden/Views/`) are thin SwiftUI. `GameView` lays panels
  out per `TableLayout` and floats the center controls; `PlayerPanel` draws
  one rotated seat; `SetupView`, `PlayerEditView`, and `HelpView`
  are the sheets and setup screen.

Requires iOS 17+. Universal (iPhone and iPad), all orientations.

## Build & run

The Xcode project is generated from `project.yml` by
[XcodeGen](https://github.com/yonaskolb/XcodeGen) and is **not** checked in.
Build and run via the [`justfile`](justfile) (`just` + `xcodegen` required):

| Command | Does |
| --- | --- |
| `just` | List all recipes |
| `just generate` | Regenerate `Sparkwarden.xcodeproj` from `project.yml` |
| `just build` | Build for the simulator |
| `just run` | Build, install, and launch in the simulator |
| `just logs` | Stream the app's logs from the booted simulator |
| `just test` | Run the test suite on the simulator |
| `just device` | Build, install, and launch on your iPhone (USB or Wi-Fi) |
| `just devices` | List connected devices and their UDIDs |
| `just shot <name>` | Screenshot the booted simulator into `marketing/screenshots/` |
| `just release <kind>` | Bump the version, upload to App Store Connect, commit and tag |
| `just open` | Open the project in Xcode |
| `just clean` | Remove build artifacts |

Always edit `project.yml`, never the generated `.xcodeproj`. The default
simulator is `iPhone 17` (override with the `sim` variable in the justfile).
Launch the app with the `--start-game` argument to skip setup and open the
table directly, e.g. `xcrun simctl launch booted com.dantanner.sparkwarden --start-game`.

Device deploy (`just device`) needs a signing team — set `DEVELOPMENT_TEAM` in
`project.yml`.

## Testing

Service logic is covered by Swift Testing suites in `SparkwardenTests`
(`just test`). UI is checked by hand in the simulator.

## Releasing

`just release <major|minor|bugfix>` bumps `MARKETING_VERSION` /
`CURRENT_PROJECT_VERSION` in `project.yml`, archives, uploads to App Store
Connect using the API key configured at the top of the justfile, then commits,
tags `v<version>`, and pushes. The working tree must be clean.
