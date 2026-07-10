//
//  SettingsView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The first page of the side menu: a small set of preferences.
///
/// Kept thin — it lays out `SettingToggleRow` components inside a grouped
/// `Form` and binds them to the injected `SettingsStore`. Persistence lives in
/// the store; strings live in `L10n`.
struct SettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section(L10n.Settings.generalSection) {
                SettingToggleRow(
                    title: L10n.Settings.launchAtLogin,
                    subtitle: L10n.Settings.launchAtLoginDetail,
                    isOn: $settings.launchAtLogin
                )

                SettingToggleRow(
                    title: L10n.Settings.showSecondRow,
                    subtitle: L10n.Settings.showSecondRowDetail,
                    isOn: $settings.showSecondRowAutomatically
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle(L10n.Sidebar.settings)
        .onAppear {
            AppLogger.shared.info("Settings appeared", category: .ui)
        }
    }
}

#Preview {
    SettingsView(settings: SettingsStore(defaults: UserDefaults(suiteName: "preview")!))
        .frame(width: 420, height: 300)
}
