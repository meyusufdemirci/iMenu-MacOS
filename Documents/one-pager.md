# iMenu — One-Pager

> A free, open-source macOS menu bar manager that gives your overflow items a
> home instead of hiding them.

| | |
|---|---|
| **Status** | Pre-validation · feasibility spike not yet done |
| **License** | Free & open source |
| **Platform** | macOS 26.5+ (SwiftUI, native) |
| **Owner** | Nefarius |
| **Last updated** | 2026-07-10 |

---

## The problem

Power users — especially developers — accumulate a lot of menu bar items. On a
modern MacBook the **notch** eats horizontal space, and macOS silently **clips**
whatever doesn't fit. You end up with, say, 20 status items but only ~15
visible. The rest are simply gone from view — no scroll, no overflow, no way to
click them without quitting other apps or unplugging a display.

## The solution

**iMenu shows the clipped items in a second row directly below the system menu
bar.** A single button in the menu bar reveals a persistent, glanceable shelf
holding everything macOS hid. Instead of *concealing* overflow behind a popover
(the incumbent approach), iMenu *surfaces* it.

- **Expand, don't hide** — every item stays visible and one click away.
- **Built for people who live in the menu bar all day** — glance, don't dig.

## Target user

Developers and heavy power users who spend most of their day at the computer and
have more menu bar items than the bar can physically show.

## Differentiation

The category is mature and mostly free (Ice, Thaw) or wounded-paid (Bartender).
The vast majority of these tools **hide** overflow behind a chevron/popover you
click to reveal. iMenu's wedge is the opposite mental model:

| | Ice / Bartender / Hidden Bar | **iMenu** |
|---|---|---|
| Overflow model | Conceal behind a click | **Persistent visible second row** |
| Interaction | Reveal-on-demand popover | Always-glanceable shelf |
| Best for | Keeping the bar tidy | Keeping everything *visible* |

> **Positioning rule:** we lead with the second-row UX. We do **not** market
> ourselves as "the one that doesn't crash" — a competitor's temporary bug is a
> vanishing window, not a moat.

## Competitive landscape

- **[Ice](https://github.com/jordanbaird/Ice)** — free, open source, actively
  maintained, the current default recommendation. The real bar to clear.
- **[Thaw](https://github.com/stonerl/Thaw)** — free, open source.
- **[Bartender](https://www.macbartender.com/)** — paid incumbent; lost goodwill
  after the 2024 ownership change and Sonoma screen-recording-permission scare.

## What "success" looks like (free OSS)

There is no revenue. Success is:
- **Adoption** — real daily users (not GitHub stars).
- **Reliability** — the pitch is a better UX; any crash undercuts it.
- **Maintained** — survives each yearly macOS release. This is where solo
  menu-bar tools usually die.

## The one big risk

The **entire product depends on one unproven technical bet**: can we reliably
render a persistent, clickable second row of *other apps'* clipped menu bar
items — using permitted APIs — across the notch, multiple displays, Stage
Manager, Spaces, and full-screen, and keep it working across macOS updates?

Those items are owned by other processes; we can't re-parent them. Tools like
this historically rely on **Screen Recording** or **Accessibility** permissions
to render their own representation of the hidden region. That permission cost is
a real product decision, and the mechanic itself is fragile ground Apple has
restricted before.

## Immediate next steps

1. **Feasibility spike (this week, throwaway):** prove a live, clickable second
   row on a real machine; document which permissions it forces.
2. **Verify the incumbent's state (30 min):** read Ice's recent issues/commits —
   is the instability real, widespread, and unfixed, or already patched?
3. **Write the one-sentence differentiator** with no reference to competitors
   being buggy.
4. **Only then** invest in real engineering, notarization (~$99/yr Apple
   Developer account), and the TDD/component scaffolding.

> Gate to real product work: **the spike works** *and* **we can state why the
> second row is genuinely better on its own merits.**
