//
//  MenuBarItemChip.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI
import AppKit

/// A single menu bar item rendered as an icon-only tile, sized to sit in a row
/// that previews the menu bar itself.
///
/// Prefers an explicit SF Symbol (`systemSymbolName`) when one is known — the
/// system items Control Center vends all share one app icon, so a representative
/// symbol (the same glyph macOS draws) reads far better. Otherwise it uses the
/// owning app's icon (resolved from `bundleIdentifier`), since the Accessibility
/// API can't hand us the real status-item glyph, and falls back to a generic
/// symbol when neither is available. Symbols are tinted with `fallbackColor`
/// (callers pass `.primary` so the glyph adapts to light/dark like a real menu bar
/// item). The `title` isn't shown; it's the accessibility label so the icon-only
/// tile stays legible to VoiceOver.
struct MenuBarItemChip: View {

    /// Glyphs iMenu draws itself because SF Symbols has no equivalent. Passed
    /// through the `systemSymbolName` channel as its `rawValue`, so the tile renders
    /// these with a bundled vector instead of `Image(systemName:)`.
    enum CustomGlyph: String {
        case bluetooth = "imenu.glyph.bluetooth"
    }

    private let title: String
    private let systemSymbolName: String?
    private let bundleIdentifier: String?
    private let fallbackColor: Color

    init(title: String, systemSymbolName: String?, bundleIdentifier: String?, fallbackColor: Color = .white) {
        self.title = title
        self.systemSymbolName = systemSymbolName
        self.bundleIdentifier = bundleIdentifier
        self.fallbackColor = fallbackColor
    }

    var body: some View {
        icon
            .frame(width: 22, height: 22)
            .padding(9)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(title)
    }

    @ViewBuilder
    private var icon: some View {
        if let systemSymbolName {
            symbolIcon(systemSymbolName)
        } else if let appIcon {
            Image(nsImage: appIcon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: "app.dashed")
                .font(.title3)
                .foregroundStyle(fallbackColor)
        }
    }

    /// Renders an icon named by `systemSymbolName`: an app-drawn `CustomGlyph` when
    /// the name matches one, otherwise the SF Symbol of that name.
    @ViewBuilder
    private func symbolIcon(_ name: String) -> some View {
        switch CustomGlyph(rawValue: name) {
        case .bluetooth:
            BluetoothGlyph()
                .foregroundStyle(fallbackColor)
        case nil:
            Image(systemName: name)
                .font(.title3)
                .foregroundStyle(fallbackColor)
        }
    }

    /// The owning app's icon, when the item carries a resolvable bundle id.
    private var appIcon: NSImage? {
        guard let bundleIdentifier,
              let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return nil }
        return app.icon
    }
}

#Preview {
    HStack(spacing: 10) {
        MenuBarItemChip(title: "Wi-Fi", systemSymbolName: "wifi", bundleIdentifier: nil)
        MenuBarItemChip(title: "Battery", systemSymbolName: "battery.100", bundleIdentifier: nil)
        MenuBarItemChip(title: "Finder", systemSymbolName: nil, bundleIdentifier: "com.apple.finder")
        MenuBarItemChip(title: "Clock", systemSymbolName: "clock", bundleIdentifier: nil)
    }
    .padding()
    .background(Color.accentColor)
}
