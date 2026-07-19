# CLAUDE.md

Guidance for Claude Code (and any contributor) when working in this repository.

## Project

**iMenu** — a free, open-source, native macOS **menu bar manager**.
macOS silently clips menu bar items that don't fit the available width (a problem
the notch makes worse), and gives users no way to reorder or hide items short of
⌘-dragging them by hand. iMenu is a **Layout editor that edits the real menu bar
in place**: a window with **Visible/Hidden** sections where dragging reorders the
real items and moving one to Hidden tucks it behind iMenu's **chevron menu bar
toggle**, which doubles as the divider and shows or hides the hidden group in one
click — the width-expansion mechanic the incumbents (Ice, Bartender, Hidden Bar)
use, folded into a single status item.

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

### Current status — reading, reordering, and hiding all proven on device

The product has narrowed from the original "second row" idea to a **Layout
editor that edits the real menu bar in place**. The history matters: an earlier
spike built a persistent second row plus `AXPress` click-forwarding, then
`7edb760` **removed all of it** (second row, click-forwarding, divider-collapse),
reducing Layout to a local-only organizer. Since then two real menu bar effects
have been added and **validated on real hardware**: **reordering** (synthesized
⌘-drag) and **hiding** (width expansion behind the chevron toggle, which now
doubles as the divider itself).

- **Reading other apps' items works.** `AccessibilityMenuBarProvider`
  enumerates every running app's `AXExtrasMenuBar` through the Accessibility
  API, reads each item's title and on-screen x-position, and returns them
  ordered left-to-right. **This is the chosen read mechanism** (of the three the
  PRD weighed — spacing manipulation / Accessibility / Screen Recording). Its
  **permission cost**: the app must run **un-sandboxed** and the user must grant
  **Accessibility**. The provider also retains the live `AXUIElement`s so it can
  re-read a single item's *current* frame on demand (`MenuBarItemLocating`).
- **Reordering the real menu bar works (validated on device).** Reordering an
  item **within the Visible section** on the Layout page drives the real bar:
  `LayoutStore` hands the move to `SynthesizedMenuBarItemReorderer`, which reads
  the item's and its new neighbor's live frames and posts a **synthesized ⌘-drag**
  (`CGEvent`, in `SynthesizedMenuBarItemRelocator`) to physically relocate the
  item — automating the ⌘-drag a user would do by hand.
- **Hiding works (single-item design; layout verified via the window list).**
  iMenu owns a **single status item**: a chevron toggle that **doubles as the
  divider** (`MenuBarStatusItemController` + `StatusBarChevron`, replacing the
  earlier SwiftUI `MenuBarExtra` and the still-earlier two-item chevron + `│`
  separator design). Hidden items live to the chevron's **left**; clicking it
  expands the item's own `.length` (~10000pt, clamped by macOS to ~5000),
  pushing everything on its left off-screen — the classic overflow-manager
  mechanic, since macOS has **no API to hide another app's status item**.
  Because a freshly created item lands **rightmost** (where expanding would
  swallow the visible items too), every expand is preceded by a once-per-session
  **park**: `MenuBarHideController.willExpand` →
  `LayoutStore.prepareDividerForHiding()` ⌘-drags the chevron just left of the
  leftmost visible item. That preparation **reports success** (`willExpand` and
  `prepareDividerForHiding` return `Bool`): the park slot is latched only when
  the park actually succeeded, a failed park keeps a Layout hide local (no real
  drag), and a failed preparation **aborts the expand and reverts + persists
  the visible state** — expanding unparked is the failure mode that blanks the
  whole bar. For the same reason the persisted hide state is
  restored via `applyPersistedState(hasHiddenItems:)` **after** the app wires
  that hook and loads the items — not in the controller's `init` — and a
  persisted "hidden" is **dropped (and re-persisted as visible) when the Hidden
  section is empty**: restoring it would blank real items the user never chose
  to hide, which is exactly how a stale flag from an old session kept the
  chevron invisible at every launch. While expanded, the chevron
  is drawn at the **right edge of a full-button-width image** (a centered
  full-width image ≡ right-aligned), and the right-click menu pops up anchored
  to the button's trailing edge. Moving an item between **Visible and Hidden**
  on the Layout page drags the real item across the chevron
  (`SynthesizedMenuBarHider` via the `MenuBarHiding` seam). The toggle itself
  is instant (a length change, no cursor movement) and its state persists
  (`MenuBarHideController`). The AppKit menu reaches SwiftUI's `openWindow`
  through the `WindowActions` bridge.

> ⚠️ **Hard-won on-device lessons — do not regress these.**
> On macOS 26 the menu bar is **rendered by Control Center in its own windows**
> (layer 25, one per display); the app's own `NSStatusItem` window frame is *not*
> where the item appears. Practical consequences, all observed on this machine:
> **subviews added to the status button are not reliably composited** — keep any
> custom look inside `button.image` (hence the full-width trailing-chevron image
> while expanded); a requested `.length` of 10000 is **clamped to ~5000** (read
> the real width back before sizing the image — measured: `button.bounds.width`
> reflects the clamped width **synchronously**, right after setting `.length`);
> and a **fresh status item lands rightmost**, so expanding without parking
> first swallows every third-party
> item — never expand before the divider is parked (`willExpand` hook), and
> restore persisted hide state only after the full pipeline is wired
> (`applyPersistedState(hasHiddenItems:)`, not `init`). More measured facts:
> with `variableLength` the item **does not shrink while the full-width
> expanded image is still attached** — `collapse()` swaps in the small glyph
> *before* setting an **explicit** small length (never `variableLength`, so the
> collapsed width is definite regardless of attached content); and the app's
> own synthesized park/hide ⌘-drags end with a **⌘-flagged mouse-up on the
> chevron button itself**, so the click handler **ignores ⌘-modified clicks**
> (also correct for a user hand-⌘-dragging the chevron — a rearrange is not a
> toggle). **Debugging trap that cost hours:** this app has a **stale
> sandbox-era container** (`~/Library/Containers/com.nefarius.iMenu`), and the
> `defaults` CLI reads/writes the **container's** plist for such bundle ids —
> while the un-sandboxed app uses `~/Library/Preferences/com.nefarius.iMenu.plist`.
> The two disagree; trust the app's own logs or `plutil -p` on the real plist,
> never `defaults read com.nefarius.iMenu`. Also: `AppLogger` info/debug lines
> don't reach `log show` from Xcode-launched runs, and the interactive shell
> aliases `log` — use `/usr/bin/log show --info` against an `open`-launched
> build to see the app's actual decisions. The divider needs a **visible glyph** at
> the parking ⌘-drag's grab point: a 1px invisible item can't be grabbed (the
> drag caught the neighboring item instead) — the grab target is the chevron
> itself. The retired two-item design also showed **creation order is not
> reliable** (roles had to be assigned by comparing actual frames); remember that
> if a second owned item ever returns. The ⌘-drag hides the cursor and restores
> it, but tuning knobs (step count, per-step delay, drop margin) may need
> re-tuning per macOS release. **Still unverified:** eyeballs-on-screen check of
> the expanded chevron glyph (the window-list geometry is verified; pixels are
> not), the item's `autosaveName` position persistence under Control Center,
> OS-pinned items (clock, Control Center), multiple/external displays, Stage
> Manager, Spaces, full-screen; re-establishing the arrangement after other apps
> relaunch (v1 is manual: the user re-hides once). The store/coordinator logic is
> unit-tested; the `NSStatusItem`/CGEvent glue is not.

- **Working conventions** below are **in force** — the code follows them (TDD,
  components, `L10n`, `AppError`, `AppLogger`). The throwaway-spike exemption no
  longer applies.
- Note: the app reads *all* extras items and lets the user arrange them (a
  Visible/Hidden split) rather than acting on overflow automatically.
  `MenuBarClipDetector` does classify which items are clipped (PRD FR1), but
  today that result is **log-only** — it doesn't drive any hiding.

> **Docs to reconcile:** `Documents/prd.md` and `Documents/one-pager.md` still
> carry the original "persistent second row" concept and the "gated on
> feasibility spike / do not build product engineering" framing. The shipped
> direction is the Layout editor + separator-hide + chevron toggle described
> above. Update them when you next touch the product docs so they match.

### Non-goals (v1)

- Not a full menu bar *customization* suite (icon theming, spacing editors,
  per-app hide rules, search) — v1 wins on the Layout editor + one-click
  hide toggle, not breadth.
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
  iMenuApp.swift              # @main: owns shared state, the Window + the menu bar controller
  MainView.swift              # Root window: NavigationSplitView side menu (keep it thin)
  Navigation/
    SidebarItem.swift         # The side-menu pages (Layout, Permissions, Settings, About)
    AppNavigation.swift       # @Observable selected-page state, shared by window + menu bar
    WindowID.swift            # Stable id for the single main window
    WindowActions.swift       # Bridge: AppKit menu → SwiftUI openWindow
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
      MenuBarHiding.swift                  # Store's seam: hide/show item X, park the divider (+ Null impl)
      SynthesizedMenuBarHider.swift        # Coordinator: drags items across the divider
      SeparatorControlling.swift           # Seam: expand/collapse the divider + its frame (+ Null impl)
      StatusBarChevron.swift               # Live impl: the chevron NSStatusItem that doubles as the width-expanding divider
      MenuBarHideController.swift          # @Observable hide state; persists, drives the divider
      MenuBarStatusItemController.swift    # AppKit owner: the single chevron status item + right-click menu
    Permissions/
      PermissionsView.swift         # Permissions page (Accessibility status + grant)
      PermissionsStore.swift        # @Observable permission state
      AccessibilityAuthorizing.swift  # Authorizer protocol + system-backed impl
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
