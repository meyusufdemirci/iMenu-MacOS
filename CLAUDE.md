# CLAUDE.md

Guidance for Claude Code (and any contributor) when working in this repository.

## Project

**iMenu** — a free, open-source, native macOS **menu bar overflow manager**.
macOS silently clips menu bar items that don't fit the available width (a problem
the notch makes worse). Instead of *hiding* the overflow behind a click-to-reveal
popover the way incumbents (Ice, Bartender, Hidden Bar) do, iMenu **surfaces** it:
it renders the clipped items in a **persistent second row directly below the
system menu bar**, toggled from a single menu bar control. The bet is that for
people who live in their menu bar all day, *seeing* everything beats *digging*
for it.

| | |
|---|---|
| Platform | macOS (deployment target **26.5**) · macOS only |
| UI | SwiftUI, native |
| Language | Swift (language mode 5.0; toolchain Swift 6.3 / Xcode 26.6) |
| Bundle ID | `com.nefarius.iMenu` |
| Runtime | **Un-sandboxed** (`ENABLE_APP_SANDBOX = NO`); needs **Accessibility** permission to read other apps' menu bar items |
| License / model | Free & open source; no paid tier, accounts, or telemetry |
| Distribution | Notarized direct download — **no Mac App Store** (sandbox forbids the required APIs) |
| Unit tests | **Swift Testing** (`import Testing`, `@Test`, `#expect`) |
| UI tests | XCTest (`XCUIApplication`) |

Product docs live in `Documents/`: [`one-pager.md`](Documents/one-pager.md) and
[`prd.md`](Documents/prd.md). Read them for full product context (personas,
positioning, user stories, milestones); the essentials for working in this repo
are below. **Keep this file consistent with those docs** — if they change, update
here.

### Current status — reading proven; real reordering coded, unproven on device

The product has narrowed from the original "second row" idea to a **Layout
editor that edits the real menu bar in place**. The history matters: an earlier
spike built a persistent second row plus `AXPress` click-forwarding, then
`7edb760` **removed all of it** (second row, click-forwarding, divider-collapse),
reducing Layout to a local-only organizer. The current direction re-adds a real
menu bar effect — **reordering** — via a different mechanic.

- **Reading other apps' items works.** `AccessibilityMenuBarProvider`
  enumerates every running app's `AXExtrasMenuBar` through the Accessibility
  API, reads each item's title and on-screen x-position, and returns them
  ordered left-to-right. **This is the chosen read mechanism** (of the three the
  PRD weighed — spacing manipulation / Accessibility / Screen Recording). Its
  **permission cost**: the app must run **un-sandboxed** and the user must grant
  **Accessibility**. The provider also retains the live `AXUIElement`s so it can
  re-read a single item's *current* frame on demand (`MenuBarItemLocating`).
- **Reordering the real menu bar is coded.** Reordering an item **within the
  Visible section** on the Layout page drives the real bar: `LayoutStore` hands
  the move to `SynthesizedMenuBarItemReorderer`, which reads the item's and its
  new neighbor's live frames and posts a **synthesized ⌘-drag** (`CGEvent`, in
  `SynthesizedMenuBarItemRelocator`) to physically relocate the item — automating
  the ⌘-drag a user would do by hand. Moving an item to **Hidden** stays a local
  list edit only.

> ⚠️ **The synthesized ⌘-drag is the fragile bet — coded but unproven on device.**
> Whether macOS honors a *synthesized* ⌘-drag for every third-party item is
> unverified; the step count, per-step delay, drop margin, and whether the
> explicit Command key events help are the tuning knobs. It **moves the real
> cursor** (~150ms) by design, so it runs on a user-initiated Layout drop, not
> silently. **Also unverified:** OS-pinned items (clock, Control Center) that
> won't move, and behavior across the notch, multiple/external displays, Stage
> Manager, Spaces, and full-screen. Assume it may need re-fixing on each major
> macOS release — treat it as unproven until exercised on real hardware. The pure
> geometry and store/coordinator logic are unit-tested; only the CGEvent post is not.

- **Working conventions** below are **in force** — the code follows them (TDD,
  components, `L10n`, `AppError`, `AppLogger`). The throwaway-spike exemption no
  longer applies.
- Note: the app does **not** try to detect the OS's clip point (PRD FR1). It
  reads *all* extras items and lets the user arrange them (a Visible/Hidden
  split), rather than auto-detecting overflow.

> **Docs to reconcile:** `Documents/prd.md` and `Documents/one-pager.md` still
> carry the original "gated on feasibility spike / do not build product
> engineering" framing. Update them when you next touch the product docs so they
> match this state.

### Non-goals (v1)

- Not a full menu bar *customization* suite (icon theming, spacing editors,
  per-app hide rules, search) — v1 wins on the second-row idea, not breadth.
- No paid tier, licensing, telemetry-for-revenue, accounts, or cloud sync.
- No Mac App Store build; no Windows / Linux / iOS.

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
  iMenuApp.swift              # @main: owns shared state, defines the Window + MenuBarExtra
  MainView.swift              # Root window: NavigationSplitView side menu (keep it thin)
  Navigation/
    SidebarItem.swift         # The side-menu pages (Layout, Permissions, Settings, About)
    AppNavigation.swift       # @Observable selected-page state, shared by window + menu bar
    WindowID.swift            # Stable id for the single main window
  Features/                   # One folder per screen/feature
    Layout/
      LayoutView.swift              # Layout page: Visible/Hidden drag-between sections
      LayoutStore.swift             # @Observable; splits + orders, persists, drives real reorder
      MenuBarItemDescriptor.swift   # Value type: one menu bar item as plain data
      MenuBarLayoutProviding.swift  # Provider protocol + SampleMenuBarLayoutProvider
      AccessibilityMenuBarProvider.swift  # Real provider: reads AXExtrasMenuBar + locates live items
      ReorderableMenuBarRow.swift   # Drag-and-drop row for one section
    SystemBar/                      # Editing the real macOS menu bar (synthesized ⌘-drag)
      MenuBarItemReordering.swift          # Store's seam: "put item X next to neighbor Y" (+ Null impl)
      SynthesizedMenuBarItemReorderer.swift # Coordinator: reads live frames, computes drop, drags
      MenuBarItemDragGeometry.swift        # Pure geometry: drop point beside a neighbor + drag path
      MenuBarItemLocating.swift            # Seam: an item's current on-screen frame by id
      MenuBarItemRelocating.swift          # Seam: the low-level "⌘-drag from A to B" intent
      SynthesizedMenuBarItemRelocator.swift # Live impl: posts the ⌘-drag CGEvents
    Permissions/
      PermissionsView.swift         # Permissions page (Accessibility status + grant)
      PermissionsStore.swift        # @Observable permission state
      AccessibilityAuthorizing.swift  # Authorizer protocol + system-backed impl
    MenuBar/
      MenuBarContent.swift          # The MenuBarExtra menu (Open / Settings / About / Quit)
    Settings/
      SettingsStore.swift           # @Observable, UserDefaults-backed preferences
      SettingsView.swift            # Settings page — composes components
    About/
      SocialLink.swift              # Value type: the author's external profile links
      AboutView.swift               # About page — author, links, free-to-use note
  Components/                 # Reusable, self-contained SwiftUI views
    CardView.swift
    PrimaryButton.swift
    SettingToggleRow.swift
    SocialLinkButton.swift          # Bordered button that opens an external link
    MenuBarItemChip.swift           # Icon-only tile for one menu bar item
    LayoutSectionView.swift         # A titled Layout section wrapping ReorderableMenuBarRow
    PermissionStatusRow.swift       # One permission row (status badge + grant button)
  Core/                       # App-wide infrastructure (no UI)
    ErrorHandling/
      AppError.swift          # The single app-wide error type
    Logging/
      LogLevel.swift          # Severity (debug < info < warning < error)
      LogCategory.swift       # Stable subsystem tags (ui, menuBar, permissions, …)
      LogEntry.swift          # Value type for one log record
      LogHandler.swift        # Protocol: where a record goes
      OSLogHandler.swift      # Production handler → Apple unified log
      AppLogger.swift         # Facade: AppLogger.shared.info(…)
    Localization/
      L10n.swift              # Type-safe localized-string accessors
      Localizable.xcstrings   # String Catalog (English source)
iMenuTests/                   # Swift Testing unit tests
iMenuUITests/                 # XCTest UI tests
```

## Working conventions

These are the standing rules for **product code** (Milestone 1+). Follow them for
every change once past the feasibility spike (see _Current status_ above) — the
throwaway Milestone 0 spike is exempt.

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
- Screens (like `MainView` / `SettingsView`) **compose** components and stay thin — they wire
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
AppLogger.shared.info("Layout screen appeared", category: .ui)
AppLogger.shared.warning("Cache miss", category: .persistence)
AppLogger.shared.error(appError, category: .menuBar)
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
