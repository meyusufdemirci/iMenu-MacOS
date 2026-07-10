# iMenu — Product Requirements Document (PRD)

| | |
|---|---|
| **Product** | iMenu — macOS menu bar overflow manager |
| **Author** | Nefarius |
| **Status** | Draft · **gated on feasibility spike** |
| **Version** | 0.1 |
| **Last updated** | 2026-07-10 |
| **License / model** | Free, open source |
| **Platform** | macOS 26.5+ · SwiftUI · native |

> ⚠️ **This PRD is conditional.** The core mechanic (rendering a second row of
> other apps' clipped menu bar items) is **not yet proven feasible**. Sections
> below marked _Spike-gated_ must not be built until Milestone 0 (Feasibility
> Spike) succeeds. If the spike fails, the product does not exist in this form.

---

## 1. Overview

macOS clips menu bar items that don't fit the available width — a problem made
worse by the notch. iMenu recovers the clipped items and displays them in a
**persistent second row directly beneath the system menu bar**, revealed and
managed through a single menu bar control.

Where incumbents (Ice, Bartender, Hidden Bar) **hide** overflow behind a
click-to-reveal popover, iMenu **surfaces** overflow into an always-visible
shelf. The bet: for people who live in their menu bar all day, *seeing*
everything beats *digging* for it.

## 2. Goals & non-goals

### Goals
- **G1** — Make clipped/overflow menu bar items visible and clickable again.
- **G2** — Present them in a persistent second row below the menu bar (the
  signature differentiator), not a hidden popover.
- **G3** — Be reliable enough that stability is a feature, not a liability.
- **G4** — Stay maintainable by a solo maintainer across yearly macOS releases.
- **G5** — Ship as a free, notarized, direct-download open-source app.

### Non-goals (v1)
- **NG1** — No paid tier, licensing, or telemetry-for-revenue.
- **NG2** — Not a full menu bar *customization* suite (icon theming, spacing
  editors, per-app rules) — that competes with Ice head-on on breadth. v1 wins
  on the second-row idea, not feature count.
- **NG3** — No Mac App Store build (sandbox forbids the required APIs).
- **NG4** — No Windows/Linux/iOS. macOS only.
- **NG5** — No cloud/account/sync.

## 3. Target users & personas

**Primary — "The Developer Power User"**
Spends all day at the machine. Runs 20+ menu bar utilities (VPN, Docker, Git
client, clipboard manager, battery/CPU monitors, sound tools, etc.). On a
notch MacBook, several are permanently clipped. Wants them *visible at a glance*,
not one-more-click away.

**Secondary — "The Multi-Display Professional"**
Docks/undocks between a laptop screen and external monitors; the set of visible
items changes constantly as width changes. Wants a stable overflow area that
doesn't shuffle.

## 4. Positioning & competitive context

- **Ice** (free, OSS, actively maintained) is the bar to clear. It is the
  default recommendation. iMenu must justify itself *next to* Ice, for free.
- **Positioning rule:** lead with the **second-row UX**. Do **not** position on
  "competitors are currently buggy" — that reason dies the day they ship a fix.
- **One-sentence differentiator (to be finalized after spike):**
  _"iMenu keeps every menu bar item visible in a second row, so you glance
  instead of hunting through a popover."_

## 5. User stories

- **US1** — As a developer with a clipped menu bar, I want to see the hidden
  items in a row below the bar so I can read their status without clicking.
- **US2** — As a user, I want to click any item in the second row and have it
  behave exactly as it would in the real menu bar (open its menu / toggle).
- **US3** — As a user, I want to toggle the second row on/off from a menu bar
  control so it's there when I need it and gone when I don't.
- **US4** — As a user, I want the second row to survive plugging/unplugging an
  external display without breaking or losing items.
- **US5** — As a first-run user, I want a clear explanation of *why* iMenu needs
  Accessibility/Screen Recording permission before I'm asked to grant it.
- **US6** — As a user, I want iMenu to launch at login and be reliably present.

## 6. Functional requirements

> Requirements marked _(Spike-gated)_ depend on Milestone 0 succeeding and may be
> revised based on which mechanism (Accessibility vs. Screen Recording vs.
> spacing manipulation) actually proves viable.

- **FR1 _(Spike-gated)_** — Detect which menu bar items are currently clipped /
  not visible.
- **FR2 _(Spike-gated)_** — Render the clipped items in a second row directly
  below the system menu bar.
- **FR3 _(Spike-gated)_** — Forward user clicks on second-row items to the real
  items so their menus/actions trigger correctly.
- **FR4** — Provide a menu bar control to show/hide the second row.
- **FR5** — Keep the second row correct as menu bar width changes (display
  connect/disconnect, resolution change, item add/remove).
- **FR6** — Handle the notch: never place the row under or behind the notch.
- **FR7** — Behave sanely across multiple displays (define which display shows
  the row; document the choice).
- **FR8** — First-run permission onboarding that explains each permission in
  plain language before the OS prompt.
- **FR9** — Launch at login (user-toggleable).
- **FR10** — Settings window: toggle row, choose target display, launch-at-login,
  appearance.
- **FR11** — Graceful degradation: if a required permission is revoked, show a
  clear, recoverable state — never a crash or a blank shelf.

## 7. UX & flows

**Menu bar control** — a single iMenu status item. Click reveals the second row
(or it stays pinned, per setting) and provides access to Settings/Quit.

**Second row** — a horizontal shelf under the menu bar containing the clipped
items, styled to feel native. Each entry is clickable and reflects the live
state of the underlying item where possible.

**First-run onboarding** — a short sequence: what iMenu does → which permission
it needs and exactly why → the OS grant prompt → confirmation the row is live.

**Settings** — minimal: row visibility behavior, target display, launch at
login, appearance. Built from reusable components (`Components/`), screen stays
thin per repo conventions.

## 8. Technical approach & the critical risk

### 8.1 The core unknown (must be resolved first)
Menu bar overflow items belong to **other processes**. iMenu cannot move or
re-parent them. Approaches used by this class of tool:

1. **Spacing manipulation** — insert a hidden separator that pushes items
   off-screen into a controlled zone.
2. **Accessibility API** — enumerate and activate other apps' status items.
3. **Screen Recording** — capture the menu bar region and render a copy
   (Bartender's historically controversial route).

Each carries different **permission costs**, **fragility**, and **App Store
eligibility**. The spike must determine which (if any) delivers a reliable,
clickable second row using permitted APIs.

### 8.2 Known hard constraints to validate in the spike
- Notch geometry.
- Multiple / external displays; docking transitions.
- Stage Manager, Spaces, full-screen apps.
- Survival across macOS point releases (menu bar internals change).
- Which permission prompt(s) the mechanism forces on the user.

### 8.3 Platform risk
This category sits on fragile, sometimes-private API surface Apple has
restricted before (the Sonoma screen-recording-permission change hit Bartender).
Assume the mechanic may need re-fixing on each major macOS release. Maintenance
commitment is a first-class product requirement, not an afterthought.

### 8.4 Engineering conventions (once past the spike)
Per `CLAUDE.md`:
- **SwiftUI**, native, deployment target macOS 26.5.
- **TDD** with Swift Testing (`import Testing`, `@Test`, `#expect`); UI tests in
  XCTest. Design for testability via injected protocols.
- **Components** in `iMenu/Components/`; screens compose and stay thin.
- **Errors** via the single `AppError` type, mapped at boundaries.
- **Logging** via `AppLogger` (never `print`); categorize with `LogCategory`.
- **Localization** English-only shipping, but all strings routed through `L10n`
  + `Localizable.xcstrings` — no hardcoded user-facing strings.
- Distribution: notarized direct download (Apple Developer account, ~$99/yr).
  **No** Mac App Store build.

## 9. Milestones

### Milestone 0 — Feasibility Spike _(BLOCKING, throwaway code)_
Prove a live, clickable second row of clipped items on a real Mac. Test on a
notch machine + at least one external display. Document which permission(s) it
requires. **No TDD, no components, no localization, no branding.**
**Exit gate:** it works *and* we can name which permission it costs.
If it fails → stop; reconsider the product.

### Milestone 1 — MVP (only if M0 passes)
FR1–FR6 implemented properly with the chosen mechanism, TDD, components,
permission onboarding (FR8), basic settings (FR10), launch at login (FR9).

### Milestone 2 — Robustness
FR5/FR7 hardening across displays & transitions, FR11 degradation handling,
notch edge cases, appearance polish.

### Milestone 3 — Release
Notarization, install/onboarding polish, README + docs, GitHub release, Reddit /
community launch.

## 10. Success metrics

- **Adoption:** real daily active users (self-reported / opt-in), not stars.
- **Reliability:** crash-free sessions; the pitch is a better UX, so this is
  non-negotiable.
- **Maintenance health:** time-to-fix after each macOS release; still working N
  months post-launch.
- **Differentiation validation:** qualitative signal that users prefer the
  visible second row over popover-hide.

## 11. Open questions

1. Which mechanism (spacing / Accessibility / Screen Recording) actually works,
   and what permission does it force?
2. On multi-display setups, which display hosts the second row — and is that a
   setting or a rule?
3. Is a permanent second row genuinely preferred over hide-in-popover, or is it a
   novelty? (Needs real user feedback.)
4. Is Ice/Thaw instability real, widespread, and unfixed — or already patched?
   (30-minute check; do not build strategy on a rumor.)
5. How do we present/limit permission scope to keep user trust (post-Bartender
   sensitivity)?

## 12. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Core mechanic isn't feasible with permitted APIs | Product doesn't exist | Milestone 0 spike **before** any product engineering |
| "Competitors are broken" window closes | Loses reason-to-exist | Position on second-row UX, not stability of rivals |
| macOS update breaks the mechanic | App rots | Budget for yearly re-fix; treat maintenance as a requirement |
| Heavy permission prompt scares users | Low adoption | Transparent onboarding; use least-invasive viable mechanism |
| New app is the crashy one (no scar tissue) | Undercuts the pitch | Rigorous edge-case testing (notch/displays/Spaces) before release |
| Solo maintainer burnout | Abandonment | Keep scope narrow (NG2); don't chase Ice's breadth |

## 13. Out of scope (v1)

Menu bar icon theming, custom spacing editors, per-app hide rules, search across
items, cloud sync, accounts, paid features, Mac App Store distribution,
non-macOS platforms.
