//
//  DividerMenuBarCollapser.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import AppKit

/// The live implementation of `SystemMenuBarCollapsing`: owns **two** menu bar
/// status items — a fixed-width, always-visible **toggle** arrow and an invisible
/// **spacer** just to its left — and grows the spacer to hide/reveal the items
/// parked to the spacer's left (milestones 0.5 path **(a)** — the divider trick
/// used by Hidden Bar / Dozer, the reliable form of the milestone's ⌘-drag idea).
///
/// **Why two items.** A single item can't both *be* the visible control and *be*
/// the thing that expands: when it grows to `expandedLength`, its glyph rides off
/// the left edge with it, so once collapsed the user has no arrow left to click to
/// bring the bar back. Splitting the jobs fixes that — the toggle keeps
/// `naturalLength` and never moves, so it's always a click target; only the
/// zero-width spacer to its left grows (`MenuBarCollapseGeometry.lengths`).
///
/// **Ordering.** The spacer must sit to the toggle's **left** so that when it grows
/// it shoves the parked items (further left) off while the toggle (to its right,
/// anchored toward the clock) stays put. New status items insert to the left of an
/// app's existing ones, so the toggle is created **first** (ends up rightmost) and
/// the spacer **second** (lands to its left). This ordering is an on-device
/// assumption that rides with milestone 0.9 validation; if macOS lays them out the
/// other way the user can ⌘-drag them into order.
///
/// Whether widening *our* spacer actually shoves *other apps'* items off the bar is
/// the core unknown of the whole product, so this type is currently wired for a
/// **hands-on primitive test** on real hardware (milestones 0.5, "prove the
/// primitive first"):
///
/// - `install()` shows both items **eagerly** at launch and makes the toggle
///   click-to-toggle, so it's easy to find and exercise.
/// - The `MenuBarExtra` menu also exposes a debug toggle (a second reliable click
///   target).
/// - Every toggle logs both items' live geometry (`x`, `length`, screen width) so
///   the test leaves a trail in the unified log.
///
/// The manual test: ⌘-drag one icon to the **left** of the toggle, then toggle. If
/// that icon disappears while the arrow stays, the primitive works and the fragile
/// per-item drag automation can be built on top; if not, the active approach is dead.
///
/// AppKit glue, used from the main actor (status items are UI), which the callers
/// already are.
final class DividerMenuBarCollapser: NSObject, SystemMenuBarCollapsing {

    /// The always-visible, always-clickable arrow. Fixed at `naturalLength`; clicking
    /// it toggles the hidden zone.
    private var toggleItem: NSStatusItem?

    /// The invisible item just left of the toggle. Zero-width while open; grows to
    /// `expandedLength` when collapsed to push the parked items off the bar.
    private var spacerItem: NSStatusItem?

    private(set) var isCollapsed = false

    /// The parking boundary in global x — the toggle's left edge, which items must be
    /// dragged to the **left** of to be hidden. `MenuBarItemPlacer` reads only its
    /// `minX` (identical in Cocoa and global display space) and drops items just left
    /// of it. The spacer sits at zero width immediately to the toggle's left, so the
    /// toggle's edge *is* the boundary. `nil` before the items are installed. Meant to
    /// be read while open — collapsing grows the spacer, not the toggle, so the toggle
    /// stays put, but there's no on-screen drop room past a collapsed bar anyway.
    var dividerScreenFrame: CGRect? {
        toggleItem?.button?.window?.frame
    }

    /// Eagerly creates the toggle and spacer and wires the toggle's click-to-toggle.
    /// Call once at startup so the user can find the arrow, ⌘-drag icons to its left,
    /// and click it to exercise the collapse primitive.
    func install() {
        let toggle = ensureToggleItem()
        toggle.button?.target = self
        toggle.button?.action = #selector(handleClick)
        _ = ensureSpacerItem()
        logState("installed")
    }

    /// Clicking the toggle toggles the hidden zone — the hands-on primitive test.
    @objc private func handleClick() {
        setCollapsed(!isCollapsed)
    }

    func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        let lengths = MenuBarCollapseGeometry.lengths(
            collapsed: collapsed,
            screenWidth: menuBarScreenWidth()
        )
        // The toggle width is invariant (set for good measure); only the spacer moves.
        ensureToggleItem().length = lengths.toggle
        ensureSpacerItem().length = lengths.spacer
        isCollapsed = collapsed
        logState("setCollapsed=\(collapsed)")
    }

    // MARK: - Status items

    /// Builds the toggle on first use: the visible arrow glyph the user finds, clicks
    /// to toggle the hidden zone, and ⌘-drags items past, with a localized
    /// accessibility label. Fixed at `naturalLength`.
    private func ensureToggleItem() -> NSStatusItem {
        if let toggleItem { return toggleItem }

        let item = NSStatusBar.system.statusItem(withLength: MenuBarCollapseGeometry.naturalLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "chevron.left.circle.fill",
                accessibilityDescription: L10n.SystemBar.dividerAccessibilityLabel
            )
            button.image?.isTemplate = true
            button.toolTip = L10n.SystemBar.dividerTooltip
        }
        toggleItem = item
        return item
    }

    /// Builds the spacer on first use: an invisible, inert item (no glyph, no click
    /// action) whose only job is to grow. Created after the toggle so it lands to the
    /// toggle's left. Starts at `spacerOpenLength` (zero) so it reserves no space.
    private func ensureSpacerItem() -> NSStatusItem {
        if let spacerItem { return spacerItem }

        let item = NSStatusBar.system.statusItem(withLength: MenuBarCollapseGeometry.spacerOpenLength)
        // No image and no target/action: the spacer is never a control, just width.
        item.button?.image = nil
        spacerItem = item
        return item
    }

    // MARK: - Diagnostics

    /// Logs both items' live geometry so the on-device test leaves a trail: where
    /// iMenu's toggle and spacer sit and how wide they are at each toggle. Console.app
    /// → subsystem `com.nefarius.iMenu`, category `menuBar`.
    private func logState(_ context: String) {
        let toggleX = toggleItem?.button?.window?.frame.origin.x ?? -1
        let toggleLength = toggleItem?.length ?? -1
        let spacerX = spacerItem?.button?.window?.frame.origin.x ?? -1
        let spacerLength = spacerItem?.length ?? -1
        AppLogger.shared.info(
            "System bar \(context): toggle(x=\(Int(toggleX)) length=\(Int(toggleLength))) "
            + "spacer(x=\(Int(spacerX)) length=\(Int(spacerLength))) screenWidth=\(Int(menuBarScreenWidth()))",
            category: .menuBar
        )
    }

    /// Width of the screen hosting the system menu bar — the primary display at the
    /// global origin, matching how `AccessibilityMenuBarProvider` locates the bar.
    private func menuBarScreenWidth() -> CGFloat {
        let screen = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
        return screen?.frame.width ?? 0
    }
}
