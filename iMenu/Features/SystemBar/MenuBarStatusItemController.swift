//
//  MenuBarStatusItemController.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import AppKit

/// Owns iMenu's menu-bar presence: a **single status item** — the chevron toggle that
/// also plays the hidden/visible divider (`StatusBarChevron`). Replaces the old SwiftUI
/// `MenuBarExtra`, and the even older two-item chevron + `│` separator design.
///
/// - **Left-click** the chevron toggles hide/show (via `MenuBarHideController`, which
///   resizes this very item). The chevron flips to point the way that reveals.
/// - **Right-click** opens the menu (Show/Hide, Open, Settings, About, Quit).
///
/// One item means there is no creation-order problem to solve (the two-item design had
/// to assign roles by comparing actual on-screen positions) and no risk of the toggle
/// being pushed off-screen by a separate expander — the toggle *is* the expander, and
/// its glyph stays pinned to the trailing edge while expanded.
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

    /// The divider role of the chevron item, exposed so the app can point the Layout
    /// hider at the same instance. `nil` until `start(...)` runs.
    private(set) var separator: StatusBarChevron?

    /// The hide state the toggle reflects and drives. `nil` until `start(...)` runs.
    private(set) var hideController: MenuBarHideController?

    /// Creates the status item and wires it, returning `true` the first time (so the
    /// caller wires the hider once). Idempotent — safe to call on every view appearance;
    /// later calls no-op and return `false`. Call **after** launch (e.g. from the root
    /// view's `.task`) so the status bar is ready.
    @discardableResult
    func start(defaults: UserDefaults = .standard, menuActions: MenuActions) -> Bool {
        guard toggleItem == nil else { return false }
        self.menuActions = menuActions

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(buttonClicked(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        toggleItem = item

        let separator = StatusBarChevron(item: item)
        self.separator = separator
        hideController = MenuBarHideController(separator: separator, defaults: defaults)

        AppLogger.shared.info("Menu bar status item created", category: .lifecycle)
        return true
    }

    // MARK: - Click handling

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            hideController?.toggle()
        }
    }

    /// Pops the menu up under the chevron glyph. Anchored to the button's **trailing**
    /// edge, not attached to the item: while hidden the item is ~10000pt wide with only
    /// its trailing sliver on screen, and an attached menu would anchor to the item's
    /// (off-screen) origin.
    private func showMenu() {
        guard let button = toggleItem?.button else { return }
        let anchor = NSPoint(x: max(button.bounds.maxX - 24, 0), y: button.bounds.height + 4)
        makeMenu().popUp(positioning: nil, at: anchor, in: button)
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

    @objc private func toggleFromMenu() { hideController?.toggle() }
    @objc private func openFromMenu() { menuActions?.open() }
    @objc private func settingsFromMenu() { menuActions?.openSettings() }
    @objc private func aboutFromMenu() { menuActions?.openAbout() }
    @objc private func quitFromMenu() { menuActions?.quit() }
}
