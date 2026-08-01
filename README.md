# iMenu

A free, open-source, native macOS **menu bar overflow manager**.

macOS silently clips the menu bar items that don't fit the available width — a
problem the notch makes worse. Where incumbents (Ice, Bartender, Hidden Bar)
**hide** the overflow behind a click-to-reveal popover, iMenu **surfaces** it: it
renders the items you choose in a **persistent second row directly below the
system menu bar**, so you glance instead of hunting. The bet is that for people
who live in their menu bar all day, *seeing* everything beats *digging* for it.

> **Status — the render mechanic works; click-forwarding is next.** iMenu reads
> other apps' menu bar items through the Accessibility API and renders a live,
> persistent second row below the menu bar. That row is **display-only for now**:
> forwarding a click on a second-row item to the real menu bar extra, and
> hardening across the notch / multiple displays / Spaces / full-screen, is still
> to come. See [`Documents/prd.md`](Documents/prd.md) for the full roadmap.

---

## Table of contents

- [How it works](#how-it-works)
- [Features](#features)
- [Requirements & permissions](#requirements--permissions)
- [Getting started](#getting-started)
- [Building & running](#building--running)
- [Running the tests](#running-the-tests)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## How it works

iMenu lives in two places:

- **A menu bar control** — a single status item whose menu can **Open** the main
  window, jump to **Settings** or **About**, or **Quit**.
- **A main window** — a side-menu (`NavigationSplitView`) with four pages:
  **Layout**, **Permissions**, **Settings**, and **About**.

On the **Layout** page you see every menu bar item iMenu can read, split into two
sections you can drag between:

- **Visible** — items that stay in the system menu bar.
- **Hidden** — items iMenu surfaces in its **second row** below the menu bar.

Move an item into *Hidden* and it appears immediately in a floating bar pinned
just under the menu bar (a borderless, non-activating `NSPanel`). The split and
the order you choose are persisted, so your arrangement survives relaunches.

Reading other apps' items requires the Accessibility permission; the
**Permissions** page explains why and links straight to System Settings.

---

## Features

- 🖥️ **Native macOS + SwiftUI** — no third-party dependencies, no package
  manager, no setup beyond Xcode.
- 🪟 **Persistent second row** — a live shelf of your chosen items below the menu
  bar, positioned with pure, unit-tested geometry (right-aligned, notch-aware
  screen math).
- 🧲 **Drag-to-arrange Layout** — split items between *Visible* and *Hidden* and
  reorder within a section; the choice and order are saved to `UserDefaults`.
- 🔐 **First-class permissions page** — shows Accessibility status, prompts, and
  opens System Settings; the window even lands here at launch when it's missing.
- 🧩 **Component-driven UI** — small, reusable, self-contained views
  (`MenuBarItemChip`, `LayoutSectionView`, `PermissionStatusRow`, `CardView`, …);
  screens stay thin and just compose them.
- 🪵 **Structured logging** — a testable `AppLogger` facade over Apple's unified
  logging system (`OSLog`), with severity levels and stable subsystem categories.
- ⚠️ **Unified error handling** — a single app-wide `AppError` type conforming to
  `LocalizedError`, so user-facing messages live in one place.
- 🌍 **Localization-ready** — every user-facing string is routed through a
  type-safe `L10n` accessor and a String Catalog. Ships English-only; adding a
  language is a data change, not a code change.
- ✅ **Tested by design** — unit tests use **Swift Testing**; providers and stores
  depend on injected protocols so logic is exercised in isolation.

---

## Requirements & permissions

| | |
|---|---|
| **OS** | macOS **26.5** or later (deployment target) |
| **IDE** | Xcode **26.6** (Swift 6.3 toolchain) |
| **Language** | Swift (language mode 5.0) |
| **UI framework** | SwiftUI |
| **Bundle ID** | `com.nefarius.iMenu` |
| **Sandbox** | **Off** (`ENABLE_APP_SANDBOX = NO`) |
| **Distribution** | Notarized direct download — **no Mac App Store** (the sandbox forbids the required APIs) |

No CocoaPods, Carthage, or Swift Package Manager dependencies — clone and open.

**Accessibility permission.** iMenu reads other apps' menu bar items via the
Accessibility API, so it must run un-sandboxed and be trusted for Accessibility.
Grant it from the in-app **Permissions** page (or System Settings ›
Privacy & Security › Accessibility). Without it, the Layout page surfaces a clear,
recoverable error instead of any items. iMenu uses the permission only to *read*
your layout — it never controls other apps.

---

## Getting started

Clone the repository and open the Xcode project:

```bash
git clone <your-fork-url> iMenu
cd iMenu
open iMenu.xcodeproj
```

Then select the **iMenu** scheme and a **My Mac** destination, and press **⌘R** to
run. On first launch, grant Accessibility from the **Permissions** page so iMenu
can read your menu bar.

> **Signing.** The project ships with no development team set, so Xcode will ask
> you to pick one the first time you build. Choose your own team under
> **Signing & Capabilities** (or select *Sign to Run Locally*) — and leave
> `DEVELOPMENT_TEAM` out of any pull request.

> The project uses **file-system-synchronized groups** (`objectVersion = 77`). Any
> file you drop into the `iMenu/`, `iMenuTests/`, or `iMenuUITests/` folders on
> disk is automatically part of the build — you never hand-edit `project.pbxproj`.

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

---

## Running the tests

```bash
# Run the full suite (unit + UI) on the local Mac
xcodebuild test -scheme iMenu -destination 'platform=macOS'

# Compile the test bundle without running — a fast red/green check
xcodebuild build-for-testing -scheme iMenu -destination 'platform=macOS'
```

- **Unit tests** (`iMenuTests/`) use **Swift Testing** — `import Testing`,
  `@Test`, `#expect(...)`. They cover the pure, injectable logic: the Layout
  store's split/order/persist rules, the second-row show/hide (`SecondRowPresentation`)
  and geometry (`SecondRowPlacement`), navigation, permissions, settings, errors,
  logging, and localization.
- **UI tests** (`iMenuUITests/`) use **XCTest** with `XCUIApplication`.

> While editing, SourceKit may show `Cannot find type … in scope` or
> `No such module 'Testing'`. These are indexer artifacts across not-yet-indexed
> files — trust `xcodebuild`, not the live diagnostics.

---

## Project structure

```
iMenu/
  iMenuApp.swift              # @main: owns shared state, defines the Window + MenuBarExtra
  MainView.swift              # Root window: NavigationSplitView side menu (kept thin)
  Navigation/
    SidebarItem.swift         # The side-menu pages (Layout, Permissions, Settings, About)
    AppNavigation.swift       # @Observable selected-page state, shared by window + menu bar
    WindowID.swift            # Stable id for the single main window
  Features/                   # One folder per screen/feature
    Layout/                   #   Read menu bar items; split them Visible / Hidden
    SecondRow/                #   The persistent NSPanel row below the menu bar
    Permissions/              #   Accessibility status, prompt, and grant
    MenuBar/                  #   The MenuBarExtra menu content
    Settings/                 #   Launch-at-login & second-row preferences
    About/                    #   Author, profile links, free-to-use note
  Components/                 # Reusable, self-contained SwiftUI views + #Previews
    CardView.swift  PrimaryButton.swift  SettingToggleRow.swift  SocialLinkButton.swift
    MenuBarItemChip.swift  LayoutSectionView.swift  PermissionStatusRow.swift
  Core/                       # App-wide infrastructure (no UI)
    ErrorHandling/AppError.swift
    Logging/                  #   LogLevel, LogCategory, LogEntry, LogHandler, OSLogHandler, AppLogger
    Localization/             #   L10n.swift + Localizable.xcstrings (English source)
iMenuTests/                   # Swift Testing unit tests
iMenuUITests/                 # XCTest UI tests
```

Folders map directly to build targets: `iMenu/` → the app, `iMenuTests/` → unit
tests, `iMenuUITests/` → UI tests.

---

## Architecture

The codebase follows a few consistent patterns. If you build on it, follow them
too.

### Feature folders with injectable stores

Each screen is a folder under `Features/`. A page's state lives in an
`@Observable` store (`LayoutStore`, `PermissionsStore`, `SettingsStore`) that
depends on **protocols**, not concrete sources — `MenuBarLayoutProviding`,
`AccessibilityAuthorizing` — so tests inject stubs and previews inject samples.
Shared state (`AppNavigation`, the stores, the `SecondRowController`) is owned by
`iMenuApp` so it survives the window closing and stays in sync with the menu bar.

### Reading the real menu bar

`AccessibilityMenuBarProvider` enumerates each running app's `AXExtrasMenuBar`,
reads item titles and on-screen x-positions, and returns them ordered
left-to-right. Items are plain `MenuBarItemDescriptor` values (no live AX handles),
so they're `Equatable`/`Hashable` and cheap to diff and persist. A
`SampleMenuBarLayoutProvider` supplies realistic fixtures for previews and tests.

### The second row

`SecondRowController` (AppKit glue) hosts a borderless, non-activating `NSPanel`
that renders `SecondRowView` bound to the **shared** `LayoutStore` — so editing
the Layout page updates the row live. The decisions are split out as pure,
unit-tested types: `SecondRowPresentation` (should it show?) and
`SecondRowPlacement` (where does it sit?).

### Component-driven UI

Build screens from small, single-responsibility views. Reusable views live in
`iMenu/Components/`; each owns its own styling and ships a `#Preview`. A component
receives its data and actions through `init` parameters and closures — it never
reads global state directly. Screens compose components and stay thin.

### Logging

Use `AppLogger` for all diagnostics — never `print()`.

```swift
AppLogger.shared.info("Second row shown", category: .menuBar)
AppLogger.shared.warning("Cache miss", category: .persistence)
AppLogger.shared.error(appError, category: .permissions)
```

- Levels are ordered `debug < info < warning < error`. Anything below the minimum
  level is dropped (`.debug` in DEBUG builds, `.info` in release).
- Categories come from the `LogCategory` enum (`ui`, `menuBar`, `permissions`,
  `lifecycle`, …) — extend it rather than passing raw strings.
- Production logs go to Apple's unified logging system, visible in **Console.app**
  filtered by subsystem `com.nefarius.iMenu`. Tests inject a spy `LogHandler`.

### Error handling

There is one app-wide error type, `AppError`, conforming to `LocalizedError` and
`Equatable`.

```swift
do {
    let items = try provider.fetchItems()
} catch let error as AppError {
    AppLogger.shared.error(error, category: .menuBar)
    // surface error.errorDescription / error.recoverySuggestion in the UI
}
```

Map lower-level errors (`URLError`, decoding failures, OS errors) into an
`AppError` case **at the boundary**, and propagate `AppError` upward — never raw
framework errors. Add a new `case` (with an `errorDescription` and
`recoverySuggestion`) rather than inventing ad-hoc error types.

### Localization

The app ships **English only**, but the infrastructure is fully localized so
adding a language later is just translation.

- Never hardcode a user-facing string in a view or model. Route it through
  `L10n`, which wraps `String(localized:)`.
- Add new strings to `iMenu/Core/Localization/L10n.swift` **and** the
  `Localizable.xcstrings` catalog (source language `en`), keeping the default
  value and catalog value identical.

---

## Contributing

Contributions are welcome! This project follows **Test-Driven Development** — the
cycle is **Red → Green → Refactor**:

1. **Red** — add or adjust a Swift Testing test describing the desired behavior;
   run the suite and watch it fail (a compile failure counts).
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

- Design for testability — depend on protocols and inject them (as `LayoutStore`
  takes a `MenuBarLayoutProviding` and `AppLogger` takes a `LogHandler`); avoid
  reaching for `.shared` singletons inside logic you want to test.
- Give every new component a `#Preview`.
- Never mark work done with a failing or unwritten test.

See [`CLAUDE.md`](CLAUDE.md) for the full working conventions and the current
project status, and [`Documents/prd.md`](Documents/prd.md) /
[`Documents/one-pager.md`](Documents/one-pager.md) for product context. Open an
issue to discuss larger changes before starting, and keep pull requests focused.

---

## License

iMenu is released under the [MIT License](LICENSE). It is free to use, modify,
and distribute — there is no paid tier, no accounts, and no telemetry.
