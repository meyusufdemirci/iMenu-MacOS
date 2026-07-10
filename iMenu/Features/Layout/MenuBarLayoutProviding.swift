//
//  MenuBarLayoutProviding.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// Supplies the current set of menu bar items for the Layout page to arrange.
///
/// The Layout UI and `LayoutStore` depend on this protocol, not on any concrete
/// source, so they stay unit-testable with a stub. Today the only implementation
/// is `SampleMenuBarLayoutProvider`; a real Accessibility-API–backed provider
/// (reading other apps' menu bar extras) lands once that mechanic is proven and
/// the app runs un-sandboxed with Accessibility permission — see the feasibility
/// note in `CLAUDE.md`.
protocol MenuBarLayoutProviding {
    /// Returns the menu bar items in their current left-to-right order.
    /// - Throws: `AppError` when the items can't be read (e.g. permission).
    func fetchItems() throws -> [MenuBarItemDescriptor]
}

/// Placeholder provider that returns a realistic, fixed set of well-known menu
/// bar items so the Layout page's fetch/display/reorder flow can be built and
/// exercised before live detection exists. Not shipped as real data — it's the
/// stand-in the UI renders until the Accessibility provider replaces it.
struct SampleMenuBarLayoutProvider: MenuBarLayoutProviding {
    func fetchItems() throws -> [MenuBarItemDescriptor] {
        [
            MenuBarItemDescriptor(id: "sample.spotlight",
                                  title: L10n.Layout.Sample.spotlight,
                                  ownerName: L10n.Layout.Sample.spotlight,
                                  systemSymbolName: "magnifyingglass"),
            MenuBarItemDescriptor(id: "sample.controlCenter",
                                  title: L10n.Layout.Sample.controlCenter,
                                  ownerName: L10n.Layout.Sample.controlCenter,
                                  systemSymbolName: "switch.2"),
            MenuBarItemDescriptor(id: "sample.wifi",
                                  title: L10n.Layout.Sample.wifi,
                                  ownerName: L10n.Layout.Sample.system,
                                  systemSymbolName: "wifi"),
            MenuBarItemDescriptor(id: "sample.sound",
                                  title: L10n.Layout.Sample.sound,
                                  ownerName: L10n.Layout.Sample.system,
                                  systemSymbolName: "speaker.wave.2.fill"),
            MenuBarItemDescriptor(id: "sample.battery",
                                  title: L10n.Layout.Sample.battery,
                                  ownerName: L10n.Layout.Sample.system,
                                  systemSymbolName: "battery.100"),
            MenuBarItemDescriptor(id: "sample.focus",
                                  title: L10n.Layout.Sample.focus,
                                  ownerName: L10n.Layout.Sample.system,
                                  systemSymbolName: "moon.fill"),
            MenuBarItemDescriptor(id: "sample.keyboard",
                                  title: L10n.Layout.Sample.keyboard,
                                  ownerName: L10n.Layout.Sample.system,
                                  systemSymbolName: "keyboard"),
            MenuBarItemDescriptor(id: "sample.clock",
                                  title: L10n.Layout.Sample.clock,
                                  ownerName: L10n.Layout.Sample.system,
                                  systemSymbolName: "clock"),
        ]
    }
}
