//
//  MenuBarStatusItemController.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import AppKit

/// Owns iMenu's menu-bar presence: the visible **chevron toggle** plus the invisible
/// **separator** it controls. Replaces the old SwiftUI `MenuBarExtra`.
///
/// - **Left-click** the chevron toggles hide/show (via `MenuBarHideController`, which
///   resizes the separator). The chevron flips to point the way that reveals.
/// - **Right-click** opens the menu (Show/Hide, Open, Settings, About, Quit).
///
/// Roles are assigned by **actual position**, not creation order (macOS doesn't place
/// status items in a reliable order): both items are created, and whichever ends up on the
/// **right** becomes the chevron, the other the separator. So growing the separator can
/// never push the chevron off-screen — the chevron is always to the separator's right, and
/// stays clickable even if the app launches in the hidden state. Positioning the separator
/// relative to the *Hidden items* (the synthesized ⌘-drag) is a later concern.
///
/// Untested AppKit glue; the state it drives (`MenuBarHideController`) is unit-tested.
final class MenuBarStatusItemController: NSObject {

    /// The window-opening / quit actions the menu invokes, injected so this AppKit type
    /// stays out of SwiftUI's window plumbing (see `WindowActions`).
    struct MenuActions {
        let open: () -> Void
        let openSettings: () -> Void
        let openAbout: () -> Void
        let quit: () -> Void
    }

    private var toggleItem: NSStatusItem?
    private var menuActions: MenuActions?

    /// The separator the toggle drives, exposed so the app can point the Layout hider at
    /// the same instance. `nil` until `start(...)` runs.
    private(set) var separator: StatusBarSeparator?

    /// The hide state the toggle reflects and drives. `nil` until `start(...)` runs.
    private(set) var hideController: MenuBarHideController?

    /// Creates the status items and wires them, returning `true` the first time (so the
    /// caller wires the hider once). Idempotent — safe to call on every view appearance;
    /// later calls no-op and return `false`. Call **after** launch (e.g. from the root
    /// view's `.task`) so the status bar is ready.
    @discardableResult
    func start(defaults: UserDefaults = .standard, menuActions: MenuActions) -> Bool {
        guard toggleItem == nil else { return false }
        self.menuActions = menuActions

        // Create both items, then assign roles by their ACTUAL position — macOS doesn't
        // place status items in a reliable left/right order, so creation order can't be
        // trusted. The **rightmost** item becomes the visible chevron; the leftmost
        // becomes the expander. That way growing the separator can never push the chevron
        // off-screen (it's always to the separator's right).
        let first = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let second = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let firstRight = first.button?.window?.frame.maxX ?? 0
        let secondRight = second.button?.window?.frame.maxX ?? 0
        let toggle = firstRight >= secondRight ? first : second
        let separatorItem = firstRight >= secondRight ? second : first

        toggle.button?.target = self
        toggle.button?.action = #selector(buttonClicked(_:))
        toggle.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        toggleItem = toggle

        let separator = StatusBarSeparator(item: separatorItem)
        self.separator = separator
        hideController = MenuBarHideController(separator: separator, defaults: defaults)

        refreshChevron()
        AppLogger.shared.info("Menu bar status items created", category: .lifecycle)
        return true
    }

    // MARK: - Click handling

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            performToggle()
        }
    }

    private func performToggle() {
        hideController?.toggle()
        refreshChevron()
    }

    /// Pops up the menu under the chevron. The menu is attached only for the duration of
    /// the click, then detached so the next left-click runs the toggle action again.
    private func showMenu() {
        guard let toggleItem else { return }
        toggleItem.menu = makeMenu()
        toggleItem.button?.performClick(nil)
        toggleItem.menu = nil
    }

    // MARK: - Menu

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let hidden = hideController?.isHidden ?? false

        let toggle = NSMenuItem(
            title: hidden ? L10n.MenuBar.showHiddenItems : L10n.MenuBar.hideHiddenItems,
            action: #selector(toggleFromMenu),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())
        menu.addItem(menuItem(L10n.MenuBar.open, #selector(openFromMenu)))
        menu.addItem(menuItem(L10n.MenuBar.settings, #selector(settingsFromMenu)))
        menu.addItem(menuItem(L10n.MenuBar.about, #selector(aboutFromMenu)))
        menu.addItem(.separator())

        let quit = menuItem(L10n.MenuBar.quit, #selector(quitFromMenu), key: "q")
        menu.addItem(quit)
        return menu
    }

    private func menuItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func toggleFromMenu() { performToggle() }
    @objc private func openFromMenu() { menuActions?.open() }
    @objc private func settingsFromMenu() { menuActions?.openSettings() }
    @objc private func aboutFromMenu() { menuActions?.openAbout() }
    @objc private func quitFromMenu() { menuActions?.quit() }

    // MARK: - Chevron

    /// Points the chevron the way that reveals: left when items are shown (click to hide
    /// them off to the left), right when they're hidden (click to bring them back).
    private func refreshChevron() {
        let hidden = hideController?.isHidden ?? false
        let symbol = hidden ? "chevron.right" : "chevron.left"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: L10n.MenuBar.toggleAccessibility)
        image?.isTemplate = true
        toggleItem?.button?.image = image
    }
}
