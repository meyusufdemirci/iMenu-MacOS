//
//  MenuBarItemNaming.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation

/// Derives a human-readable label for a menu bar item from its raw Accessibility
/// attributes.
///
/// A status item's `AXTitle` is often empty — most notably every item vended by
/// **Control Center** (Battery, Bluetooth, Clock, Sound, Wi‑Fi, …), which share one
/// owning process. Their readable name lives in `AXDescription` instead (the label
/// VoiceOver announces, already localized by the OS), so we prefer that when the
/// title is missing. Priority order:
///
/// 1. the item's own **title**, unless it's a generic placeholder some apps set,
/// 2. its accessibility **description**, with any live status macOS appends for
///    VoiceOver stripped off (`"Wi‑Fi, connected, 3 bars"` → `"Wi‑Fi"`).
///
/// When neither is usable it returns `""`, letting the caller fall back to the
/// owning app's name — which for un-named third-party items (Bitwarden, WireGuard)
/// is exactly the right label.
///
/// Pure and side-effect-free so it's unit-tested directly; the AppKit provider only
/// supplies the raw attribute strings.
enum MenuBarItemNaming {

    /// The best display label for an item, or `""` when nothing usable is present.
    /// - Parameters:
    ///   - title: the item's `AXTitle`, if any.
    ///   - description: the item's `AXDescription`, if any.
    static func resolveTitle(title: String?, description: String?) -> String {
        if let title = cleaned(title), isPlaceholder(title) == false {
            return title
        }
        if let description = cleaned(description) {
            return leadingClause(description)
        }
        return ""
    }

    /// Trims surrounding whitespace/newlines; returns `nil` for empty or blank input.
    private static func cleaned(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmed.isEmpty == false else { return nil }
        return trimmed
    }

    /// The part of an accessible name before its first comma. macOS decorates a
    /// status item's `AXDescription` with live state for VoiceOver ("Wi‑Fi,
    /// connected, 3 bars", "Control Center, Screen Recording is in use"); the name
    /// itself is the leading clause. Names without a comma ("Battery", "Audio and
    /// Video Controls") pass through unchanged.
    private static func leadingClause(_ value: String) -> String {
        let head = value.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
            .first.map(String.init) ?? value
        let trimmed = head.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? value : trimmed
    }

    /// Whether a title is a generic placeholder that reads worse than the owning
    /// app's name (e.g. DeepL's status item is titled "StatusItem"). Such titles are
    /// treated as absent so the caller falls back to the owner.
    private static func isPlaceholder(_ title: String) -> Bool {
        placeholderTitles.contains(title.lowercased())
    }

    private static let placeholderTitles: Set<String> = ["statusitem", "item-0", "item"]
}
