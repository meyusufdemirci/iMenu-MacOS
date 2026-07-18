//
//  MenuBarItemSymbolsTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `MenuBarItemSymbols.symbolName(forIdentifier:)` maps a system menu bar item's
/// Accessibility identifier to a representative SF Symbol, so Control Center items
/// show their real icon rather than the one shared Control Center app glyph. The
/// identifiers mirror the real ones captured from a live menu bar.
struct MenuBarItemSymbolsTests {

    @Test func mapsKnownControlCenterIdentifiers() {
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.battery", bundleIdentifier: nil) == "battery.100")
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.wifi", bundleIdentifier: nil) == "wifi")
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.sound", bundleIdentifier: nil) == "speaker.wave.2.fill")
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.clock", bundleIdentifier: nil) == "clock")
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.controlcenter", bundleIdentifier: nil) == "switch.2")
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.audiovideo", bundleIdentifier: nil) == "waveform")
    }

    @Test func mapsBluetoothToTheCustomDrawnGlyph() {
        // SF Symbols has no Bluetooth glyph, so it resolves to the app-drawn sentinel.
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.bluetooth", bundleIdentifier: nil)
                == MenuBarItemChip.CustomGlyph.bluetooth.rawValue)
    }

    @Test func mapsInputMenuByOwningBundleIdentifier() {
        // The input-source menu exposes no per-item AXIdentifier, so it's keyed on its owner.
        #expect(MenuBarItemSymbols.symbolName(identifier: nil, bundleIdentifier: "com.apple.TextInputMenuAgent") == "keyboard")
    }

    @Test func matchingIsCaseInsensitive() {
        #expect(MenuBarItemSymbols.symbolName(identifier: "COM.APPLE.MENUEXTRA.WIFI", bundleIdentifier: nil) == "wifi")
        #expect(MenuBarItemSymbols.symbolName(identifier: nil, bundleIdentifier: "COM.APPLE.TEXTINPUTMENUAGENT") == "keyboard")
    }

    @Test func prefersItemIdentifierOverBundleIdentifier() {
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.apple.menuextra.wifi", bundleIdentifier: "com.apple.TextInputMenuAgent") == "wifi")
    }

    @Test func returnsNilWhenNothingMapped() {
        #expect(MenuBarItemSymbols.symbolName(identifier: "com.some.thirdparty.app", bundleIdentifier: "com.some.thirdparty") == nil)
        #expect(MenuBarItemSymbols.symbolName(identifier: nil, bundleIdentifier: nil) == nil)
    }
}
