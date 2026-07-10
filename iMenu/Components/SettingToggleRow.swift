//
//  SettingToggleRow.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A single preference row: a title, an optional explanatory subtitle, and a
/// trailing switch bound to a `Bool`.
///
/// Centralizing the layout here keeps every setting visually consistent. Like
/// every component, it takes its data and binding via `init` and reads no
/// global state, so it drops into any `Form`.
struct SettingToggleRow: View {
    private let title: String
    private let subtitle: String?
    @Binding private var isOn: Bool

    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isOn = true
    return Form {
        SettingToggleRow(
            title: "Launch at login",
            subtitle: "Open iMenu automatically when you log in.",
            isOn: $isOn
        )
    }
    .formStyle(.grouped)
    .frame(width: 360)
}
