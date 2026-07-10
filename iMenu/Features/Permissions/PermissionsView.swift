//
//  PermissionsView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI
import AppKit

/// The Permissions page of the side menu.
///
/// Shows the state of each system permission iMenu relies on. For now that's
/// **Accessibility**, which is required to read other apps' menu bar items — when
/// it isn't granted, the row offers a button that prompts and opens System
/// Settings. Kept thin: it composes `PermissionStatusRow` and re-reads the state
/// through its `PermissionsStore` on appear and whenever the app is reactivated
/// (e.g. returning from System Settings).
struct PermissionsView: View {

    /// The source of truth for the current permission state.
    let store: PermissionsStore

    var body: some View {
        Form {
            Section {
                PermissionStatusRow(
                    title: L10n.Permissions.accessibility,
                    subtitle: L10n.Permissions.accessibilityDetail,
                    isGranted: store.accessibilityGranted,
                    grantTitle: L10n.Permissions.openSystemSettings,
                    grantAction: { store.requestAccess() }
                )
            } header: {
                Text(L10n.Permissions.accessibilitySection)
            } footer: {
                Text(L10n.Permissions.accessibilityFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(L10n.Sidebar.permissions)
        .onAppear {
            AppLogger.shared.info("Permissions screen appeared", category: .ui)
            store.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.refresh()
        }
    }
}

#Preview {
    PermissionsView(store: PermissionsStore())
        .frame(width: 460, height: 300)
}
