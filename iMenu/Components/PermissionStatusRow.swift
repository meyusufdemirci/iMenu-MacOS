//
//  PermissionStatusRow.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A single permission row: a title and explanation, a colored status badge
/// (granted / not granted), and — when not granted — a trailing button to grant
/// it.
///
/// Like every component it takes its data and action via `init` and reads no
/// global state, so it drops into any `Form`.
struct PermissionStatusRow: View {
    private let title: String
    private let subtitle: String
    private let isGranted: Bool
    private let grantTitle: String
    private let grantAction: () -> Void

    init(
        title: String,
        subtitle: String,
        isGranted: Bool,
        grantTitle: String,
        grantAction: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isGranted = isGranted
        self.grantTitle = grantTitle
        self.grantAction = grantAction
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                statusBadge
                if !isGranted {
                    Button(grantTitle, action: grantAction)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusBadge: some View {
        Label {
            Text(isGranted ? L10n.Permissions.granted : L10n.Permissions.notGranted)
        } icon: {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(isGranted ? Color.green : Color.orange)
    }
}

#Preview {
    Form {
        PermissionStatusRow(
            title: "Accessibility",
            subtitle: "Lets iMenu read your menu bar items.",
            isGranted: false,
            grantTitle: "Open System Settings",
            grantAction: {}
        )
        PermissionStatusRow(
            title: "Accessibility",
            subtitle: "Lets iMenu read your menu bar items.",
            isGranted: true,
            grantTitle: "Open System Settings",
            grantAction: {}
        )
    }
    .formStyle(.grouped)
    .frame(width: 460)
}
