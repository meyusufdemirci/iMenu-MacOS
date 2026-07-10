//
//  PermissionsView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The Permissions page of the side menu.
///
/// Placeholder for now — it will host the system-permission prompts (e.g.
/// Accessibility / Screen Recording) iMenu needs to render the second row. Kept
/// thin: it only sets its navigation title and logs its appearance.
struct PermissionsView: View {
    var body: some View {
        Color.clear
            .navigationTitle(L10n.Sidebar.permissions)
            .onAppear {
                AppLogger.shared.info("Permissions screen appeared", category: .ui)
            }
    }
}

#Preview {
    PermissionsView()
}
