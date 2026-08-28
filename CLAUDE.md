# Sparkwarden

iOS/iPadOS life counter for Magic: The Gathering. The device sits in the
middle of the table and each player's panel is rotated to face their seat.
No ads, no analytics, no network. Repo: https://github.com/dtanner/sparkwarden
(local checkout at `~/code/sparkwarden`).

## Build & run

The Xcode project is generated from `project.yml` by XcodeGen and is **not**
checked in. Use the justfile (`just` + `xcodegen` required): `just run`,
`just test`, `just device`, `just release <major|minor|bugfix>`.

Always edit `project.yml`, never the generated `.xcodeproj`. The default
simulator is `iPhone 17` (override with the `sim` variable in the justfile).
Launching with `--start-game` skips setup and opens the table (for screenshots).

## Architecture

- **`AppModel`** (`@MainActor`, `@Observable`) is the single source of app
  state: persisted `GameSettings` (UserDefaults, JSON), the `Game` in
  progress, and the starter-roulette animation state. It keeps the screen
  awake while a game is running.
- **Services** hold the testable rules, all pure value types:
  - `Game` — life, poison, commander tax, commander damage (which also
    reduces life), death, per-seat facing overrides.
  - `TableLayout` — which seat goes where and which way it faces, for a
    given player count and orientation. Rotation is degrees clockwise;
    0 faces the bottom edge, 90 the left, 180 the top, 270 the right.
  - `StarterRoulette` — the decelerating sequence of seats the "spinning
    light" visits before landing on the winner.
- **Views** are thin SwiftUI. `GameView` builds the `TableLayout` from the
  screen size and floats the center controls (the dismissible starter prompt, then end game).
  `PlayerPanel` draws one seat, rotated as a whole so every control faces
  its player; the edge nearest the table center is kept empty so the
  center controls never cover anything.

## Conventions

- **Be concise.** Prefer the simplest design that is testable, debuggable, and
  conventional. Suggest a better approach when you see one — don't just
  implement the literal request.
- **Greenfield comments:** describe what the code *is* and why, never what it
  used to be or what changed.
- **Testing:** write tests for service logic using **Swift Testing**
  (`@Test`/`#expect`) in the `SparkwardenTests` target, run via `just test`.
  UI testing is done manually by the developer in the simulator; don't drive
  the app with UI-automation tools.
- **Docs:** README (user-facing features) and CONTRIBUTING (build/test/dev
  workflow) must stay accurate — update them in the same change that adds or
  renames a feature, recipe, or service. `Views/HelpView.swift` is the in-app
  help; keep it in step with user-visible behavior changes.
