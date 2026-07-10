//
//  LayoutView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The Layout page of the side menu.
///
/// Placeholder for now — it will host the second-row layout controls. Kept thin:
/// it only sets its navigation title and logs its appearance.
struct LayoutView: View {
    var body: some View {
        Color.clear
            .navigationTitle(L10n.Sidebar.layout)
            .onAppear {
                AppLogger.shared.info("Layout screen appeared", category: .ui)
            }
    }
}

#Preview {
    LayoutView()
}
