//
//  DividerMenuBarCollapser.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import AppKit

/// The live implementation of `SystemMenuBarCollapsing`: owns a divider
/// `NSStatusItem` and toggles its width to hide/reveal the items parked to its
/// left (milestones 0.5 path **(a)** — the divider trick used by Hidden Bar /
/// Dozer, the reliable form of the milestone's ⌘-drag idea).
///
/// When collapsed, the divider's slot expands to `MenuBarCollapseGeometry
/// .expandedLength`, which is meant to push every status item to its left off the
/// visible bar; when open it shrinks back to `naturalLength`. Whether widening
/// *our* item actually shoves *other apps'* items off the bar is the core unknown
/// of the whole product, so this type is currently wired for a **hands-on primitive
/// test** on real hardware (milestones 0.5, "prove the primitive first"):
///
/// - `install()` shows the divider **eagerly** at launch and makes it
///   click-to-toggle, so it's easy to find and exercise.
/// - The `MenuBarExtra` menu also exposes a debug toggle (a reliable click target
///   even when the divider is collapsed).
/// - Every toggle logs the divider's live geometry (`x`, `length`, screen width)
///   so the test leaves a trail in the unified log.
///
/// The manual test: ⌘-drag one icon to the **left** of iMenu's divider, then
/// toggle. If that icon disappears, the primitive works and the fragile per-item
/// drag automation can be built on top; if not, the active approach is dead.
///
/// AppKit glue, used from the main actor (status items are UI), which the callers
/// already are.
final class DividerMenuBarCollapser: NSObject, SystemMenuBarCollapsing {

    /// iMenu's divider in the system status area.
    private var statusItem: NSStatusItem?

    private(set) var isCollapsed = false

    /// Eagerly creates the visible divider and wires click-to-toggle. Call once at
    /// startup so the user can find it, ⌘-drag icons to its left, and click it to
    /// exercise the collapse primitive.
    func install() {
        let item = ensureStatusItem()
        item.button?.target = self
        item.button?.action = #selector(handleClick)
        logState("installed")
    }

    /// Clicking the divider toggles the hidden zone — the hands-on primitive test.
    @objc private func handleClick() {
        setCollapsed(!isCollapsed)
    }

    func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        let item = ensureStatusItem()
        item.length = collapsed
            ? MenuBarCollapseGeometry.expandedLength(screenWidth: menuBarScreenWidth())
            : MenuBarCollapseGeometry.naturalLength
        isCollapsed = collapsed
        logState("setCollapsed=\(collapsed)")
    }

    // MARK: - Status item

    /// Builds the divider on first use: a visible boundary glyph the user can find
    /// and ⌘-drag items past, with a localized accessibility label. Fixed at
    /// `naturalLength` until collapsed.
    private func ensureStatusItem() -> NSStatusItem {
        if let statusItem { return statusItem }

        let item = NSStatusBar.system.statusItem(withLength: MenuBarCollapseGeometry.naturalLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "chevron.left.circle.fill",
                accessibilityDescription: L10n.SystemBar.dividerAccessibilityLabel
            )
            button.image?.isTemplate = true
            button.toolTip = L10n.SystemBar.dividerTooltip
        }
        statusItem = item
        return item
    }

    // MARK: - Diagnostics

    /// Logs the divider's live geometry so the on-device test leaves a trail: where
    /// iMenu's divider sits and how wide it is at each toggle. Console.app →
    /// subsystem `com.nefarius.iMenu`, category `menuBar`.
    private func logState(_ context: String) {
        let x = statusItem?.button?.window?.frame.origin.x ?? -1
        let length = statusItem?.length ?? -1
        AppLogger.shared.info(
            "Divider \(context): x=\(Int(x)) length=\(Int(length)) screenWidth=\(Int(menuBarScreenWidth()))",
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
