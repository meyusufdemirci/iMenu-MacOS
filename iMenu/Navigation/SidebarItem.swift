//
//  SidebarItem.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// A page in the main window's side menu.
///
/// The order of the cases is the order shown in the sidebar — **Layout first**,
/// then Permissions, Settings, then About. (The default landing page is chosen
/// separately in `AppNavigation`.) Each item carries its own presentable title
/// (via `L10n`) and SF Symbol name, keeping the sidebar view a thin `ForEach`
/// over `allCases`.
enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case layout
    case permissions
    case settings
    case about

    var id: String { rawValue }

    /// Localized label shown in the sidebar and as the page's navigation title.
    var title: String {
        switch self {
        case .layout: return L10n.Sidebar.layout
        case .permissions: return L10n.Sidebar.permissions
        case .settings: return L10n.Sidebar.settings
        case .about: return L10n.Sidebar.about
        }
    }

    /// SF Symbol shown alongside the title in the sidebar.
    var systemImage: String {
        switch self {
        case .layout: return "rectangle.split.2x1"
        case .permissions: return "lock.shield"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}
