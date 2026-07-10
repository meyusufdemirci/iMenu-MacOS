//
//  MenuBarItemDescriptor.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// A single menu bar item, described as plain data.
///
/// Deliberately a pure value type — no `NSImage`, no live AX handle — so it's
/// `Equatable`/`Hashable` (easy to assert on and to diff in a `ForEach`) and
/// cheap to persist. The icon is carried as an optional SF Symbol name; the view
/// layer resolves it to an image. `id` is the stable identity used both for
/// `List` diffing and for remembering the user's chosen order.
nonisolated struct MenuBarItemDescriptor: Identifiable, Equatable, Hashable, Sendable {

    /// Stable identity (e.g. a bundle-scoped key), unique within one fetch.
    let id: String

    /// The item's own label. May be empty for icon-only items.
    let title: String

    /// The app that owns the item, shown as a subtitle.
    let ownerName: String

    /// SF Symbol used to represent the item, when one is known (sample data and
    /// fallbacks). Real items resolve their icon from `bundleIdentifier` instead.
    let systemSymbolName: String?

    /// Bundle identifier of the owning app, used to resolve its icon. `nil` for
    /// sample items or apps without a bundle id.
    let bundleIdentifier: String?

    /// What to show as the primary label: the item's title, or its owning app
    /// when the item has no title of its own (common for icon-only extras).
    var displayTitle: String {
        title.isEmpty ? ownerName : title
    }
}
