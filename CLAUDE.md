# CLAUDE.md

Guidance for Claude Code (and any contributor) when working in this repository.

## Project

**iMenu** — a native macOS application built with SwiftUI.

| | |
|---|---|
| Platform | macOS (deployment target **26.5**) |
| UI | SwiftUI |
| Language | Swift (language mode 5.0; toolchain Swift 6.3 / Xcode 26.6) |
| Bundle ID | `com.nefarius.iMenu` |
| Unit tests | **Swift Testing** (`import Testing`, `@Test`, `#expect`) |
| UI tests | XCTest (`XCUIApplication`) |

### Xcode project layout

The project uses **file-system-synchronized groups** (`objectVersion = 77`).
This is important:

> **Any file added to the `iMenu/`, `iMenuTests/`, or `iMenuUITests/` folders on
> disk is automatically part of the build. Do NOT hand-edit `project.pbxproj` to
> register new files, and do not create files outside these folders expecting
> them to compile.**

Folders map to targets: `iMenu/` → app, `iMenuTests/` → unit tests,
`iMenuUITests/` → UI tests.

## Build & test commands

```bash
# Run the full test suite (unit + UI) on the local Mac
xcodebuild test -scheme iMenu -destination 'platform=macOS'

# Just build the app
xcodebuild build -scheme iMenu -destination 'platform=macOS'

# Build the test bundle without running (fast red/green compile check)
xcodebuild build-for-testing -scheme iMenu -destination 'platform=macOS'

# List schemes / targets
xcodebuild -list -project iMenu.xcodeproj
```

> SourceKit may report `Cannot find type … in scope` or `No such module 'Testing'`
> while editing. These are **indexer artifacts** across not-yet-indexed files —
> trust `xcodebuild`, not the live diagnostics.

## Directory structure

```
iMenu/
  iMenuApp.swift            # @main entry point
  ContentView.swift         # Home screen — composes components (keep it thin)
  Components/               # Reusable, self-contained SwiftUI views
    CardView.swift
    PrimaryButton.swift
  Core/                     # App-wide infrastructure (no UI)
    ErrorHandling/
      AppError.swift        # The single app-wide error type
    Logging/
      LogLevel.swift        # Severity (debug < info < warning < error)
      LogCategory.swift     # Stable subsystem tags (ui, network, …)
      LogEntry.swift        # Value type for one log record
      LogHandler.swift      # Protocol: where a record goes
      OSLogHandler.swift    # Production handler → Apple unified log
      AppLogger.swift       # Facade: AppLogger.shared.info(…)
    Localization/
      L10n.swift            # Type-safe localized-string accessors
      Localizable.xcstrings # String Catalog (English source)
iMenuTests/                 # Swift Testing unit tests
iMenuUITests/               # XCTest UI tests
```

## Working conventions

These are the standing rules for this codebase. Follow them for every change.

### 1. Test-Driven Development (TDD)

Write the test first. The cycle is **Red → Green → Refactor**:

1. **Red** — add/adjust a Swift Testing test describing the desired behavior;
   run the suite and watch it fail (compile failure counts).
2. **Green** — write the minimum production code to make it pass.
3. **Refactor** — clean up with the tests as your safety net.

- Unit tests use **Swift Testing** (`import Testing`, `struct …`, `@Test`,
  `#expect(...)`), not XCTest. UI tests remain XCTest.
- Design for testability: depend on protocols and inject them (see `AppLogger`
  taking a `LogHandler` so tests use an in-memory spy). Avoid reaching for
  `.shared` singletons inside logic you want to test.
- Never mark work done with a failing or unwritten test.

### 2. Component approach

Build the UI from small, reusable, single-responsibility views.

- Reusable views live in `iMenu/Components/` (e.g. `CardView`, `PrimaryButton`).
- Screens (like `ContentView`) **compose** components and stay thin — they wire
  data, localization, logging, and error handling together but delegate
  presentation to components.
- Every component owns its styling so restyling happens in one place. Give each
  a `#Preview`.
- A component takes its data/actions via `init` parameters and closures; it does
  not read global state directly.

### 3. Localization — English only, for now

The app ships **English only**, but the infrastructure is fully localized so
adding a language later is a data change, not a code change.

- **Never** hardcode a user-facing string in a view or model. Route it through
  `L10n` (which wraps `String(localized:)`).
- Add new strings to `iMenu/Core/Localization/L10n.swift` **and** the
  `Localizable.xcstrings` catalog (source language `en`), keeping the default
  value and the catalog value identical.
- `SWIFT_EMIT_LOC_STRINGS` is on, so `String(localized:)` calls are also
  auto-extracted into the catalog by Xcode.

### 4. Global error handling — `AppError`

There is one app-wide error type: `AppError` (`Core/ErrorHandling/AppError.swift`).

- It conforms to `LocalizedError` (user-facing text via `L10n`) and `Equatable`
  (easy to assert in tests).
- Map lower-level errors (`URLError`, decoding failures, OS errors) into an
  `AppError` case **at the boundary**; propagate `AppError` upward, not raw
  framework errors.
- Add a new `case` (with an `errorDescription` and `recoverySuggestion`) rather
  than inventing ad-hoc error types.
- Present `errorDescription` to the user; log the error via `AppLogger`.

```swift
do {
    try loadMenu()
} catch let error as AppError {
    AppLogger.shared.error(error, category: .ui)
    show(error.errorDescription)
}
```

### 5. Logging — `AppLogger`

Use `AppLogger` for all diagnostics; never `print()`.

```swift
AppLogger.shared.info("Home screen appeared", category: .ui)
AppLogger.shared.warning("Cache miss", category: .persistence)
AppLogger.shared.error(appError, category: .network)
```

- Levels: `debug` < `info` < `warning` < `error`. Below `minimumLevel` is
  dropped (`.debug` in DEBUG builds, `.info` in release).
- Categories come from the `LogCategory` enum — extend it rather than passing
  raw strings.
- Production logs go to Apple's unified logging system (`OSLogHandler`), visible
  in **Console.app** filtered by subsystem `com.nefarius.iMenu`. Tests inject a
  spy `LogHandler`.
- Do **not** interpolate user/PII data into a log message; messages are logged
  as `public`.

## Adding a new feature (checklist)

1. Write failing Swift Testing tests for the behavior (Red).
2. Add user-facing strings to `L10n` + `Localizable.xcstrings`.
3. Implement logic; surface failures as `AppError`; log via `AppLogger`.
4. Build UI from `Components/`; keep the screen thin.
5. `xcodebuild test -scheme iMenu -destination 'platform=macOS'` → all green.
