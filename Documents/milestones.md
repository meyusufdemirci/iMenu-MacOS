# iMenu — Milestones

| | |
|---|---|
| **Product** | iMenu — macOS menu bar overflow manager |
| **Author** | Nefarius |
| **Status** | **Gated on Milestone 0 (Feasibility Spike)** — not yet passed |
| **Last updated** | 2026-07-10 |
| **Source of truth** | [`prd.md`](prd.md) §9, [`one-pager.md`](one-pager.md), [`../CLAUDE.md`](../CLAUDE.md) |

> ⚠️ **The product is pre-validation.** Everything rests on one unproven bet:
> can we reliably render a **persistent, clickable second row of *other apps'*
> clipped menu bar items** — using permitted APIs — across the notch, multiple
> displays, Stage Manager, Spaces, and full-screen, and keep it working across
> macOS updates? Those items belong to other processes; **we cannot re-parent
> them.** Milestone 0 exists to answer this. **If it fails, the product does not
> exist in this form.**

This document expands the milestone summary in [`prd.md` §9](prd.md) into a
working task breakdown. Requirements (`FR1`–`FR11`) trace back to
[`prd.md` §6](prd.md).

---

## Legend

| Marker | Meaning |
|---|---|
| ✅ | Done |
| 🟡 | Partially done / scaffolding exists, core still unproven |
| ⬜ | Not started |
| 🔒 | Blocked until Milestone 0 passes |

> **Note on current code.** Some product-grade scaffolding (SwiftUI structure,
> TDD, components, `L10n`, Permissions/Settings pages, a floating second-row
> panel, an Accessibility item *reader*) already exists in the repo. This is
> **ahead of the strict "spike first, throwaway code" rule** in `CLAUDE.md` §
> _Current status_. It usefully de-risks Milestone 1, but it does **not** mean
> Milestone 0 is passed — the four hard unknowns below are still open. Treat the
> spike's outcome, not the existing UI, as the gate.

---

## Milestone 0 — Feasibility Spike **(BLOCKING · throwaway code)**

**Goal:** Prove a **live, clickable second row of the clipped items** on a real
Mac.

**Exit gate:** it **works** on a notch machine **and** at least one external
display, **and** we can **name which permission(s)** it costs. Works → start
Milestone 1. Fails → **stop**; reconsider the product.

**Rules (per `CLAUDE.md`):** the spike is **throwaway** — **no** TDD, no
components, no localization, no branding. Its only job is to answer "does the
mechanic work, and what does it cost?"

### The core unknown

Menu bar overflow items belong to **other processes**; iMenu cannot move or
re-parent them. Three candidate mechanisms, each with a different permission /
fragility / maintenance cost (see [`prd.md` §8.1](prd.md)):

1. **Spacing manipulation** — own a hidden separator/divider status item and
   push other items off-screen into a controlled zone.
2. **Accessibility API** — enumerate and activate other apps' status items.
3. **Screen Recording** — capture the menu bar region and render a copy
   (Bartender's historically controversial route).

The spike must determine **which combination actually works** with permitted
APIs, and what it forces the user to grant.

### Tasks

| # | Task | Covers | Status |
|---|---|---|---|
| 0.1 | **Enumerate other apps' menu bar items** via Accessibility (`AXExtrasMenuBar`): titles + on-screen positions. | FR1 (part) | ✅ `Features/Layout/AccessibilityMenuBarProvider.swift` |
| 0.2 | **Float a shelf below the menu bar** — a borderless non-activating panel that renders item chips. | FR2 (part) | ✅ `Features/SecondRow/*` — borderless `.nonactivatingPanel` at `.statusBar` level, hung below the menu bar and driven live by the shared `LayoutStore` via `SecondRowController` (started from `MainView`). *Remaining caveats belong to other tasks: faithful glyphs → 0.6; click-forwarding → 0.7.* |
| 0.3 | **Placement geometry** — position the row below the menu bar, out from under the notch. | FR6 (part) | ✅ `SecondRowPlacement` — hangs the row below the menu bar band (which *is* the notch band on notched Macs), so **notch-safe by construction**; regression-guarded by `doesNotIntersectTheNotch` and clamps an over-wide row to stay on-screen. Unit-tested. *On-device sign-off (notch Mac + external display, Spaces, full-screen) rides with 0.9; the row's which-display choice (`NSScreen.main`) is also 0.9's.* |
| 0.4 | **Real clip detection** — determine which items are actually *clipped/overflowed* (off the right edge or behind the notch), not merely enumerated. Compare item `x`+width against the visible bar region and the notch exclusion zone. | FR1 | ✅ `MenuBarClipDetector` (pure, 9 unit tests) classifies each item's frame against the usable region + notch zone; `AccessibilityMenuBarProvider` reads full frames (position **+ size**), derives the notch from the screen's auxiliary areas, and logs the clipped count per fetch. *On-hardware AX confirmation (a notch Mac actually reporting clipped frames in a detectable way) rides with 0.9.* |
| 0.5 | **Remove/hide a chosen item from the real menu bar** — the central bet. Decide and prove one path: **(a) active** — own a divider status item + simulate a ⌘-drag to move a specific third-party item past it, then collapse it off-screen; or **(b) passive** — only mirror items macOS *already* clipped (no moving). *(a) is what makes a manual Visible↔Hidden toggle actually control the system bar; it needs Accessibility + synthesized events.* | Core mechanic | ⬜ |
| 0.6 | **Faithful icons** — obtain each item's *rendered* status-item glyph. Accessibility does **not** expose it (we currently fall back to the owning app's icon). Real fidelity likely forces **Screen Recording** — this decides a permission cost. | FR2 | ⬜ |
| 0.7 | **Click forwarding** — a click on a second-row chip must trigger the real item's menu/action (via `AXPress` or a synthesized click at the item's location). The panel is `ignoresMouseEvents = true` today — display-only. | FR3 | ⬜ |
| 0.8 | **Mechanism + permission decision** — explicitly evaluate spacing vs. Accessibility vs. Screen Recording, pick the viable combination, and **write down which permission(s) it forces**. This is the second half of the exit gate. | Exit gate | ⬜ |
| 0.9 | **Validate on real hardware** — on a notch Mac + external display: notch never covered (FR6); which display hosts the row + dock/undock transitions (FR5/FR7); Stage Manager, Spaces, full-screen; live correctness as width changes (item add/remove, resolution change) (FR5). | FR5–FR7 | ⬜ |
| 0.10 | **Survival + write-up** — note which APIs are private/fragile, estimate the yearly re-fix cost, and record a **go/no-go** with the permission cost. | Maintenance | ⬜ |

### The four hard unknowns still open

Despite the scaffolding, none of these is proven yet — they are the milestone:

1. ~~**Real clip detection** (0.4)~~ — *rule built, unit-tested, and wired (✅); residual: confirm on a notch Mac that live AX exposes a clipped item's geometry → folded into 0.9.*
2. **Making a chosen item leave the real menu bar** (0.5) ← *the "move to Hidden → disappears from the real bar" request*
3. **Click-forwarding so second-row items actually work** (0.7)
4. **The permission/mechanism decision, validated on real hardware** (0.6, 0.8, 0.9)

---

## Milestone 1 — MVP **(only if M0 passes)** 🔒

Implement `FR1`–`FR6` **properly** with the mechanism chosen in M0, now under the
full [`CLAUDE.md`](../CLAUDE.md) conventions: **TDD** (Swift Testing), **reusable
components**, `AppError`, `AppLogger`, `L10n` for every string.

### Tasks

| # | Task | Req | Status |
|---|---|---|---|
| 1.1 | Productionize the chosen detect/hide/render mechanism from the spike behind a clean, injected protocol (rewrite, don't lift, spike code). | FR1–FR3 | 🔒 |
| 1.2 | Second row: real glyphs, correct ordering, live updates as items change. | FR2, FR5 | 🟡→🔒 (`SecondRowView` scaffold exists) |
| 1.3 | Click-forwarding wired to real items, with correct hit-testing. | FR3 | 🔒 |
| 1.4 | Menu bar control to show/hide the row (pin vs. reveal-on-click per setting). | FR4 | 🟡 (`MenuBarExtra` present) |
| 1.5 | Notch handling — never place the row under/behind the notch. | FR6 | 🟡 (`SecondRowPlacement`) |
| 1.6 | **Permission onboarding (FR8)** — first-run flow explaining each permission in plain language *before* the OS prompt. | FR8 | 🟡 (`Features/Permissions/*` scaffold) |
| 1.7 | **Launch at login (FR9)** — user-toggleable (`SMAppService`). | FR9 | 🟡 (Settings toggle present; wiring TBD) |
| 1.8 | **Basic settings (FR10)** — toggle row, choose target display, launch-at-login, appearance. | FR10 | 🟡 (`Features/Settings/*` scaffold) |
| 1.9 | Layout page: curate which items live in the second row (Visible ↔ Hidden), backed by the real hide mechanic from M0. | G1, G2 | 🟡 (UI done; not yet wired to a real hider) |

**Exit gate:** a real user can install iMenu, grant the documented permission via
onboarding, and see + click their clipped items in a persistent second row.

---

## Milestone 2 — Robustness 🔒

Harden the mechanic across the messy real world.

| # | Task | Req | Status |
|---|---|---|---|
| 2.1 | Multi-display / docking transitions — stable behavior on connect/disconnect, resolution change; define + document which display hosts the row. | FR5, FR7 | 🔒 |
| 2.2 | Notch edge cases across machine models and menu bar densities. | FR6 | 🔒 |
| 2.3 | Stage Manager, Spaces, full-screen correctness. | FR5 | 🔒 |
| 2.4 | **Graceful degradation (FR11)** — if a required permission is revoked, show a clear, recoverable state — never a crash or a blank shelf. | FR11 | 🔒 |
| 2.5 | Appearance polish (light/dark, materials, spacing) to feel native. | — | 🔒 |
| 2.6 | Reliability pass — crash-free sessions; edge-case + UI test coverage (notch/displays/Spaces). | G3 | 🔒 |

**Exit gate:** no crashes or blank shelves across displays, Spaces, and permission
revocation; the row stays correct through docking and width changes.

---

## Milestone 3 — Release 🔒

Ship it.

| # | Task | Status |
|---|---|---|
| 3.1 | Notarization — Apple Developer account (~$99/yr), signed + notarized direct-download build (**no** Mac App Store). | 🔒 |
| 3.2 | Install / onboarding polish. | 🔒 |
| 3.3 | README + docs; finalize the one-sentence differentiator (no "competitors are buggy" framing). | 🔒 |
| 3.4 | GitHub release. | 🔒 |
| 3.5 | Community launch (Reddit / relevant communities). | 🔒 |

**Exit gate:** a notarized build a stranger can download, install, and use;
adoption measured by **real daily users**, not GitHub stars.

---

## Gating & dependencies

```
M0 (Feasibility Spike)  ──✗──►  STOP — reconsider the product
        │
        ✓ works + permission cost named
        ▼
M1 (MVP)  ─►  M2 (Robustness)  ─►  M3 (Release)
```

- **Nothing spike-gated (`FR1`–`FR3`, and by extension the product) is built for
  real until M0 passes.** Existing scaffolding does not change this gate.
- The chosen mechanism from **M0.8** dictates the permission story used
  throughout M1's onboarding (**FR8**) and M2's degradation handling (**FR11**).
- **Maintenance is a first-class requirement**, not an afterthought — assume the
  mechanic needs re-fixing on each major macOS release ([`prd.md` §8.3](prd.md)).

## Requirement → milestone traceability

| Req | Summary | Milestone |
|---|---|---|
| FR1 | Detect clipped items | M0 (prove) → M1 (build) |
| FR2 | Render second row | M0 (prove) → M1 (build) |
| FR3 | Forward clicks to real items | M0 (prove) → M1 (build) |
| FR4 | Menu bar show/hide control | M1 |
| FR5 | Stay correct as width changes | M1 → M2 (harden) |
| FR6 | Handle the notch | M1 → M2 (harden) |
| FR7 | Multi-display behavior | M1 → M2 (harden) |
| FR8 | Permission onboarding | M1 |
| FR9 | Launch at login | M1 |
| FR10 | Settings window | M1 |
| FR11 | Graceful degradation | M2 |
