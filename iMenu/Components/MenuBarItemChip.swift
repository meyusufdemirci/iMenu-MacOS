//
//  MenuBarItemChip.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A single menu bar item rendered as an icon-only tile, sized to sit in a row
/// that previews the menu bar itself.
///
/// Like every component it takes primitives via `init` and reads no global state,
/// so it drops into any horizontal stack. The `title` isn't shown — it's used as
/// the accessibility label so the icon-only tile stays legible to VoiceOver.
/// Reordering is driven by the enclosing row's drag-and-drop, not by the chip.
struct MenuBarItemChip: View {
    private let title: String
    private let systemSymbolName: String?

    init(title: String, systemSymbolName: String?) {
        self.title = title
        self.systemSymbolName = systemSymbolName
    }

    var body: some View {
        Image(systemName: systemSymbolName ?? "app.dashed")
            .font(.title3)
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .padding(9)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(title)
    }
}

#Preview {
    HStack(spacing: 10) {
        MenuBarItemChip(title: "Wi-Fi", systemSymbolName: "wifi")
        MenuBarItemChip(title: "7°", systemSymbolName: "cloud")
        MenuBarItemChip(title: "Battery", systemSymbolName: "battery.100")
        MenuBarItemChip(title: "14:03", systemSymbolName: "clock")
    }
    .padding()
}
