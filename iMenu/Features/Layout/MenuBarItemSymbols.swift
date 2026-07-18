//
//  MenuBarItemSymbols.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation

/// Maps a system menu bar item to a representative **SF Symbol**, keyed by its
/// Accessibility identifier.
///
/// Control Center vends all of its items (Battery, Wi‑Fi, Sound, Clock, …) from a
/// single process, so resolving an icon from the owning app's bundle yields the
/// same generic Control Center glyph for every one of them. The Accessibility API
/// can't hand us the real rendered status icon either. An SF Symbol — the same
/// system icon macOS itself draws these items with — communicates each far better.
///
/// Most values are SF Symbol names; Bluetooth resolves to a `CustomGlyph` sentinel
/// (SF Symbols has no Bluetooth glyph) that the tile draws itself. Returns `nil` for
/// anything unmapped (third-party items, system items we don't cover), letting the
/// caller fall back to the owning app's icon. Pure and side-effect-free so it's
/// unit-tested directly.
enum MenuBarItemSymbols {

    /// The icon name for a menu bar item, resolved first from its per-item
    /// `AXIdentifier`, then — for items that expose none, like the input-source menu
    /// vended by TextInputMenuAgent — from its owning app's bundle identifier.
    /// `nil` when neither is mapped.
    static func symbolName(identifier: String?, bundleIdentifier: String?) -> String? {
        if let identifier, let symbol = symbolsByIdentifier[identifier.lowercased()] {
            return symbol
        }
        if let bundleIdentifier, let symbol = symbolsByBundleIdentifier[bundleIdentifier.lowercased()] {
            return symbol
        }
        return nil
    }

    /// Known system items keyed by their per-item `AXIdentifier`.
    private static let symbolsByIdentifier: [String: String] = [
        "com.apple.menuextra.battery": "battery.100",
        "com.apple.menuextra.wifi": "wifi",
        "com.apple.menuextra.airport": "wifi",
        "com.apple.menuextra.sound": "speaker.wave.2.fill",
        "com.apple.menuextra.volume": "speaker.wave.2.fill",
        "com.apple.menuextra.clock": "clock",
        "com.apple.menuextra.controlcenter": "switch.2",
        "com.apple.menuextra.audiovideo": "waveform",
        // No Bluetooth SF Symbol exists; the tile draws this rune itself.
        "com.apple.menuextra.bluetooth": MenuBarItemChip.CustomGlyph.bluetooth.rawValue,
    ]

    /// Items with no per-item `AXIdentifier`, keyed by their owning app's bundle id.
    private static let symbolsByBundleIdentifier: [String: String] = [
        "com.apple.textinputmenuagent": "keyboard",
    ]
}
