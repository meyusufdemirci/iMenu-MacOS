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
/// Prefers the owning app's icon (resolved from `bundleIdentifier`), since the
/// Accessibility API can't hand us the real status-item glyph. When there's no
/// app icon — sample data or apps we can't resolve — it falls back to an SF
/// Symbol tinted with `fallbackColor` (white on the accent-colored Layout row;
/// `.primary` on the material second row, so it adapts to light/dark like a real
/// menu bar glyph). The `title` isn't shown; it's the accessibility label so the
/// icon-only tile stays legible to VoiceOver. Reordering is driven by the
/// enclosing row.
struct MenuBarItemChip: View {
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
        if let appIcon {
            Image(nsImage: appIcon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: systemSymbolName ?? "app.dashed")
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
