# iMenu

A native macOS application built with SwiftUI — designed as a clean, well-architected
starting point for a menu app, with production-grade infrastructure for logging, error
handling, and localization already wired in.

> **Status:** Early-stage scaffold. The home screen composes the reusable components and
> demonstrates the full logging + error-handling loop. The menu-loading logic itself is a
> clearly-marked placeholder ready for you to fill in.

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Building & running](#building--running)
- [Running the tests](#running-the-tests)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- 🖥️ **Native macOS + SwiftUI** — no third-party dependencies, no package manager, no setup beyond Xcode.
- 🧩 **Component-driven UI** — small, reusable, self-contained views (`CardView`, `PrimaryButton`); screens stay thin and just compose them.
- 🪵 **Structured logging** — a testable `AppLogger` facade over Apple's unified logging system (`OSLog`), with severity levels and stable subsystem categories.
- ⚠️ **Unified error handling** — a single app-wide `AppError` type conforming to `LocalizedError`, so user-facing messages live in one place.
- 🌍 **Localization-ready** — every user-facing string is routed through a type-safe `L10n` accessor and a String Catalog. Ships English-only; adding a language is a data change, not a code change.
- ✅ **Tested by design** — unit tests use **Swift Testing**; dependencies are injected so logic is exercised in isolation.

---

## Requirements

| | |
|---|---|
| **OS** | macOS **26.5** or later (deployment target) |
| **IDE** | Xcode **26.6** (Swift 6.3 toolchain) |
| **Language** | Swift (language mode 5.0) |
| **UI framework** | SwiftUI |
| **Bundle ID** | `com.nefarius.iMenu` |

No CocoaPods, Carthage, or Swift Package Manager dependencies — clone and open.

---

## Getting started

Clone the repository and open the Xcode project:

```bash
git clone <your-fork-url> iMenu
cd iMenu
open iMenu.xcodeproj
```

Then select the **iMenu** scheme and a **My Mac** destination, and press **⌘R** to run.

> The project uses **file-system-synchronized groups** (`objectVersion = 77`). Any file
> you drop into the `iMenu/`, `iMenuTests/`, or `iMenuUITests/` folders on disk is
> automatically part of the build — you never hand-edit `project.pbxproj`.

---

## Building & running

You can build and test entirely from the command line with `xcodebuild`:

```bash
# Build the app
xcodebuild build -scheme iMenu -destination 'platform=macOS'

# Run the app from Xcode instead: open the project and press ⌘R
```

List the available schemes and targets at any time:

```bash
xcodebuild -list -project iMenu.xcodeproj
```

### What the app does today

The home screen shows a welcome card with a **Refresh** button. Tapping it runs the
app's error-handling loop: it attempts work, logs the outcome via `AppLogger`, and shows
a localized status message — surfacing an `AppError`'s description on failure. The actual
menu-loading work is a placeholder (`performRefresh()` in `ContentView.swift`) that you
replace with real logic.

---

## Running the tests

```bash
# Run the full suite (unit + UI) on the local Mac
xcodebuild test -scheme iMenu -destination 'platform=macOS'

# Compile the test bundle without running — a fast red/green check
xcodebuild build-for-testing -scheme iMenu -destination 'platform=macOS'
```

- **Unit tests** (`iMenuTests/`) use **Swift Testing** — `import Testing`, `@Test`, `#expect(...)`.
- **UI tests** (`iMenuUITests/`) use **XCTest** with `XCUIApplication`.

> While editing, SourceKit may show `Cannot find type … in scope` or `No such module 'Testing'`.
> These are indexer artifacts across not-yet-indexed files — trust `xcodebuild`, not the live diagnostics.

---

## Project structure

```
iMenu/
  iMenuApp.swift            # @main entry point
  ContentView.swift         # Home screen — composes components (kept thin)
  Components/               # Reusable, self-contained SwiftUI views
    CardView.swift          #   Rounded material container, generic over content
    PrimaryButton.swift     #   The app's primary call-to-action button
  Core/                     # App-wide infrastructure (no UI)
    ErrorHandling/
      AppError.swift        #   The single app-wide error type
    Logging/
      LogLevel.swift        #   Severity: debug < info < warning < error
      LogCategory.swift     #   Stable subsystem tags (ui, network, …)
      LogEntry.swift        #   Value type for one log record
      LogHandler.swift      #   Protocol: where a record goes
      OSLogHandler.swift    #   Production handler → Apple unified log
      AppLogger.swift       #   Facade: AppLogger.shared.info(…)
    Localization/
      L10n.swift            #   Type-safe localized-string accessors
      Localizable.xcstrings #   String Catalog (English source)
iMenuTests/                 # Swift Testing unit tests
iMenuUITests/               # XCTest UI tests
```

Folders map directly to build targets: `iMenu/` → the app, `iMenuTests/` → unit tests,
`iMenuUITests/` → UI tests.

---

## Architecture

The codebase follows a few consistent patterns. If you build on it, follow them too.

### Component-driven UI

Build screens from small, single-responsibility views. Reusable views live in
`iMenu/Components/`; each owns its own styling and ships a `#Preview`. A component
receives its data and actions through `init` parameters and closures — it never reads
global state directly. Screens like `ContentView` **compose** components and stay thin.

```swift
CardView {
    VStack {
        Text(L10n.Home.title)
        PrimaryButton(L10n.Home.refresh, systemImage: "arrow.clockwise") {
            refresh()
        }
    }
}
```

### Logging

Use `AppLogger` for all diagnostics — never `print()`.

```swift
AppLogger.shared.info("Home screen appeared", category: .ui)
AppLogger.shared.warning("Cache miss", category: .persistence)
AppLogger.shared.error(appError, category: .network)
```

- Levels are ordered `debug < info < warning < error`. Anything below the minimum level
  is dropped (`.debug` in DEBUG builds, `.info` in release).
- Categories come from the `LogCategory` enum — extend it rather than passing raw strings.
- Production logs go to Apple's unified logging system, visible in **Console.app** filtered
  by subsystem `com.nefarius.iMenu`. Tests inject a spy `LogHandler` instead.
- The handler is injected, so the whole pipeline is unit-testable.

### Error handling

There is one app-wide error type, `AppError`, conforming to `LocalizedError` and `Equatable`.

```swift
do {
    try loadMenu()
} catch let error as AppError {
    AppLogger.shared.error(error, category: .ui)
    show(error.errorDescription)
}
```

Map lower-level errors (`URLError`, decoding failures, OS errors) into an `AppError` case
**at the boundary**, and propagate `AppError` upward — never raw framework errors. Add a
new `case` (with an `errorDescription` and `recoverySuggestion`) rather than inventing
ad-hoc error types.

### Localization

The app ships **English only**, but the infrastructure is fully localized so adding a
language later is just translation.

- Never hardcode a user-facing string in a view or model. Route it through `L10n`,
  which wraps `String(localized:)`.
- Add new strings to `iMenu/Core/Localization/L10n.swift` **and** the `Localizable.xcstrings`
  catalog (source language `en`), keeping the default value and catalog value identical.

---

## Contributing

Contributions are welcome! This project follows **Test-Driven Development** — the cycle
is **Red → Green → Refactor**:

1. **Red** — add or adjust a Swift Testing test describing the desired behavior; run the
   suite and watch it fail (a compile failure counts).
2. **Green** — write the minimum production code to make it pass.
3. **Refactor** — clean up with the tests as your safety net.

When adding a new feature:

1. Write failing Swift Testing tests for the behavior.
2. Add user-facing strings to `L10n` **and** `Localizable.xcstrings`.
3. Implement the logic; surface failures as `AppError`; log via `AppLogger`.
4. Build the UI from `Components/` and keep the screen thin.
5. Make sure the suite is green:
   ```bash
   xcodebuild test -scheme iMenu -destination 'platform=macOS'
   ```

Please:

- Design for testability — depend on protocols and inject them (as `AppLogger` takes a `LogHandler`); avoid reaching for `.shared` singletons inside logic you want to test.
- Give every new component a `#Preview`.
- Never mark work done with a failing or unwritten test.

Open an issue to discuss larger changes before starting, and keep pull requests focused.

---

## License

This project is open source. Add your chosen license here (e.g. MIT) in a `LICENSE` file
at the repository root, and reference it from this section.
