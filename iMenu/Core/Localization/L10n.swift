//
//  L10n.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// Type-safe access to localized strings.
///
/// Localization is **English-only for now**, but every user-facing string is
/// routed through `String(localized:)` and stored in `Localizable.xcstrings`.
/// Adding a language later means translating the catalog — no code changes.
///
/// Keep all keys in this one file so the string surface is easy to audit.
enum L10n {

    enum App {
        static var name: String {
            String(localized: "app.name",
                   defaultValue: "iMenu",
                   comment: "The application name, shown as the sidebar title")
        }
    }

    enum Sidebar {
        static var settings: String {
            String(localized: "sidebar.settings",
                   defaultValue: "Settings",
                   comment: "Side menu label for the Settings page")
        }

        static var layout: String {
            String(localized: "sidebar.layout",
                   defaultValue: "Layout",
                   comment: "Side menu label for the Layout page")
        }

        static var permissions: String {
            String(localized: "sidebar.permissions",
                   defaultValue: "Permissions",
                   comment: "Side menu label for the Permissions page")
        }

        static var about: String {
            String(localized: "sidebar.about",
                   defaultValue: "About",
                   comment: "Side menu label for the About page")
        }
    }

    enum MenuBar {
        static var open: String {
            String(localized: "menubar.open",
                   defaultValue: "Open",
                   comment: "Menu bar item that opens the main window on its current page")
        }

        static var settings: String {
            String(localized: "menubar.settings",
                   defaultValue: "Settings",
                   comment: "Menu bar item that opens the main window on the Settings page")
        }

        static var about: String {
            String(localized: "menubar.about",
                   defaultValue: "About",
                   comment: "Menu bar item that opens the main window on the About page")
        }

        static var quit: String {
            String(localized: "menubar.quit",
                   defaultValue: "Quit iMenu",
                   comment: "Menu bar item that quits the app entirely")
        }

        /// DEBUG (milestones 0.5): manual toggle to exercise the divider-collapse
        /// primitive on real hardware. Removed once the mechanic is proven.
        static var toggleHiddenZoneDebug: String {
            String(localized: "menubar.toggleHiddenZoneDebug",
                   defaultValue: "Toggle Hidden Zone (debug)",
                   comment: "Debug menu item that collapses/expands iMenu's menu bar divider to test the hide mechanic")
        }

        /// DEBUG (milestones 0.5): exercises the synthesized ⌘-drag by auto-parking
        /// the rightmost item past iMenu's divider on real hardware. Removed once
        /// per-item auto-placement is proven.
        static var autoParkItemDebug: String {
            String(localized: "menubar.autoParkItemDebug",
                   defaultValue: "Auto-Park Rightmost Item (debug)",
                   comment: "Debug menu item that synthesizes a ⌘-drag to move the rightmost menu bar item past iMenu's divider")
        }
    }

    enum Settings {
        static var generalSection: String {
            String(localized: "settings.section.general",
                   defaultValue: "General",
                   comment: "Header for the general section of Settings")
        }

        static var launchAtLogin: String {
            String(localized: "settings.launchAtLogin",
                   defaultValue: "Launch at login",
                   comment: "Title of the launch-at-login preference")
        }

        static var launchAtLoginDetail: String {
            String(localized: "settings.launchAtLogin.detail",
                   defaultValue: "Open iMenu automatically when you log in.",
                   comment: "Explanation of the launch-at-login preference")
        }

        static var showSecondRow: String {
            String(localized: "settings.showSecondRow",
                   defaultValue: "Show the second row automatically",
                   comment: "Title of the show-second-row preference")
        }

        static var showSecondRowDetail: String {
            String(localized: "settings.showSecondRow.detail",
                   defaultValue: "Reveal clipped menu bar items in a second row when iMenu starts.",
                   comment: "Explanation of the show-second-row preference")
        }
    }

    enum Layout {
        static var visibleSection: String {
            String(localized: "layout.section.visible",
                   defaultValue: "Visible",
                   comment: "Header of the section listing items that stay in the menu bar")
        }

        static var visibleSectionDetail: String {
            String(localized: "layout.section.visible.detail",
                   defaultValue: "These stay in your menu bar.",
                   comment: "Explanation of the Visible section on the Layout page")
        }

        static var visibleEmpty: String {
            String(localized: "layout.section.visible.empty",
                   defaultValue: "Drag items here to keep them in the menu bar.",
                   comment: "Placeholder shown when the Visible section has no items")
        }

        static var hiddenSection: String {
            String(localized: "layout.section.hidden",
                   defaultValue: "Hidden",
                   comment: "Header of the section listing items surfaced in the second row")
        }

        static var hiddenSectionDetail: String {
            String(localized: "layout.section.hidden.detail",
                   defaultValue: "These move to the second row below your menu bar.",
                   comment: "Explanation of the Hidden section on the Layout page")
        }

        static var hiddenEmpty: String {
            String(localized: "layout.section.hidden.empty",
                   defaultValue: "Drag items here to show them in the second row.",
                   comment: "Placeholder shown when the Hidden section has no items")
        }

        static var reorderHint: String {
            String(localized: "layout.reorderHint",
                   defaultValue: "Drag items between Visible and Hidden, or within a section to reorder.",
                   comment: "Footer explaining what dragging does on the Layout page")
        }

        static var sampleNotice: String {
            String(localized: "layout.sampleNotice",
                   defaultValue: "These are sample items — live menu bar detection is coming soon.",
                   comment: "Footer note that the Layout list currently shows placeholder data")
        }

        static var loading: String {
            String(localized: "layout.loading",
                   defaultValue: "Reading your menu bar…",
                   comment: "Progress label shown while the Layout page loads items")
        }

        static var refresh: String {
            String(localized: "layout.refresh",
                   defaultValue: "Refresh",
                   comment: "Toolbar button that re-fetches the menu bar items")
        }

        static var retry: String {
            String(localized: "layout.retry",
                   defaultValue: "Try Again",
                   comment: "Button that retries loading after a failure on the Layout page")
        }

        static var emptyTitle: String {
            String(localized: "layout.empty.title",
                   defaultValue: "No menu bar items",
                   comment: "Title of the empty state on the Layout page")
        }

        static var emptyDescription: String {
            String(localized: "layout.empty.description",
                   defaultValue: "iMenu didn’t find any menu bar items to arrange.",
                   comment: "Description of the empty state on the Layout page")
        }

        /// Display names for the placeholder items shown until live detection
        /// exists. Localized like all user-facing strings even though the data
        /// is temporary.
        enum Sample {
            static var system: String {
                String(localized: "layout.sample.system",
                       defaultValue: "System",
                       comment: "Owning-app label for system-owned sample menu bar items")
            }

            static var spotlight: String {
                String(localized: "layout.sample.spotlight",
                       defaultValue: "Spotlight",
                       comment: "Sample menu bar item: Spotlight search")
            }

            static var controlCenter: String {
                String(localized: "layout.sample.controlCenter",
                       defaultValue: "Control Center",
                       comment: "Sample menu bar item: Control Center")
            }

            static var wifi: String {
                String(localized: "layout.sample.wifi",
                       defaultValue: "Wi-Fi",
                       comment: "Sample menu bar item: Wi-Fi status")
            }

            static var sound: String {
                String(localized: "layout.sample.sound",
                       defaultValue: "Sound",
                       comment: "Sample menu bar item: sound/volume")
            }

            static var battery: String {
                String(localized: "layout.sample.battery",
                       defaultValue: "Battery",
                       comment: "Sample menu bar item: battery status")
            }

            static var focus: String {
                String(localized: "layout.sample.focus",
                       defaultValue: "Focus",
                       comment: "Sample menu bar item: Focus / Do Not Disturb")
            }

            static var keyboard: String {
                String(localized: "layout.sample.keyboard",
                       defaultValue: "Keyboard",
                       comment: "Sample menu bar item: keyboard / input source")
            }

            static var clock: String {
                String(localized: "layout.sample.clock",
                       defaultValue: "Clock",
                       comment: "Sample menu bar item: the menu bar clock")
            }
        }
    }

    enum SecondRow {
        static var activateHint: String {
            String(localized: "secondRow.activateHint",
                   defaultValue: "Opens this menu bar item.",
                   comment: "Accessibility hint on a second-row tile: clicking it opens the real menu bar item")
        }
    }

    enum SystemBar {
        static var dividerAccessibilityLabel: String {
            String(localized: "systemBar.divider.accessibilityLabel",
                   defaultValue: "iMenu hidden-items divider",
                   comment: "Accessibility label for iMenu's menu bar divider that marks which items are hidden")
        }

        static var dividerTooltip: String {
            String(localized: "systemBar.divider.tooltip",
                   defaultValue: "Drag menu bar items to the left of this to hide them in iMenu's second row.",
                   comment: "Tooltip on iMenu's menu bar divider explaining how to park items in the hidden zone")
        }
    }

    enum Home {
        static var title: String {
            String(localized: "home.title",
                   defaultValue: "Welcome to iMenu",
                   comment: "Title shown on the home screen")
        }

        static var subtitle: String {
            String(localized: "home.subtitle",
                   defaultValue: "Your menu, one click away.",
                   comment: "Subtitle shown under the home title")
        }

        static var refresh: String {
            String(localized: "home.refresh",
                   defaultValue: "Refresh",
                   comment: "Title of the refresh button")
        }

        static var ready: String {
            String(localized: "home.status.ready",
                   defaultValue: "Ready.",
                   comment: "Default status message on the home screen")
        }

        static var refreshed: String {
            String(localized: "home.status.refreshed",
                   defaultValue: "Refreshed successfully.",
                   comment: "Status message shown after a successful refresh")
        }
    }

    enum About {
        static var author: String {
            String(localized: "about.author",
                   defaultValue: "Yusuf Demirci",
                   comment: "Name of the app's author, shown on the About page")
        }

        static var role: String {
            String(localized: "about.role",
                   defaultValue: "Developer",
                   comment: "The author's role, shown under their name on the About page")
        }

        static var free: String {
            String(localized: "about.free",
                   defaultValue: "iMenu is completely free to use.",
                   comment: "Note that the app is free, shown on the About page")
        }

        static var madeWithLove: String {
            String(localized: "about.madeWithLove",
                   defaultValue: "Made with love",
                   comment: "Sign-off shown with a heart icon at the bottom of the About page")
        }

        static var linkedIn: String {
            String(localized: "about.link.linkedin",
                   defaultValue: "LinkedIn",
                   comment: "Label for the author's LinkedIn profile link")
        }

        static var x: String {
            String(localized: "about.link.x",
                   defaultValue: "X",
                   comment: "Label for the author's X (formerly Twitter) profile link")
        }

        static var github: String {
            String(localized: "about.link.github",
                   defaultValue: "GitHub",
                   comment: "Label for the author's GitHub profile link")
        }
    }

    enum Permissions {
        static var accessibilitySection: String {
            String(localized: "permissions.accessibility.section",
                   defaultValue: "Accessibility",
                   comment: "Header for the Accessibility section of the Permissions page")
        }

        static var accessibility: String {
            String(localized: "permissions.accessibility.title",
                   defaultValue: "Accessibility",
                   comment: "Title of the Accessibility permission row")
        }

        static var accessibilityDetail: String {
            String(localized: "permissions.accessibility.detail",
                   defaultValue: "Lets iMenu read the menu bar items of other apps.",
                   comment: "Explanation of why iMenu needs Accessibility permission")
        }

        static var accessibilityFooter: String {
            String(localized: "permissions.accessibility.footer",
                   defaultValue: "iMenu uses this only to read your menu bar layout — it never controls other apps.",
                   comment: "Reassurance about how the Accessibility permission is used")
        }

        static var screenRecordingSection: String {
            String(localized: "permissions.screenRecording.section",
                   defaultValue: "Screen Recording",
                   comment: "Header for the Screen Recording section of the Permissions page")
        }

        static var screenRecording: String {
            String(localized: "permissions.screenRecording.title",
                   defaultValue: "Screen Recording",
                   comment: "Title of the Screen Recording permission row")
        }

        static var screenRecordingDetail: String {
            String(localized: "permissions.screenRecording.detail",
                   defaultValue: "Lets iMenu capture how your menu bar items look so it can show their icons in the second row.",
                   comment: "Explanation of why iMenu needs Screen Recording permission")
        }

        static var screenRecordingFooter: String {
            String(localized: "permissions.screenRecording.footer",
                   defaultValue: "iMenu captures only your menu bar to mirror item icons — nothing else on your screen is recorded or stored.",
                   comment: "Reassurance about how the Screen Recording permission is used")
        }

        static var granted: String {
            String(localized: "permissions.status.granted",
                   defaultValue: "Granted",
                   comment: "Status badge shown when a permission is granted")
        }

        static var notGranted: String {
            String(localized: "permissions.status.notGranted",
                   defaultValue: "Not granted",
                   comment: "Status badge shown when a permission has not been granted")
        }

        static var openSystemSettings: String {
            String(localized: "permissions.openSystemSettings",
                   defaultValue: "Open System Settings",
                   comment: "Button that opens System Settings to grant a permission")
        }
    }

    enum Errors {
        static var unknown: String {
            String(localized: "error.unknown",
                   defaultValue: "An unknown error occurred.",
                   comment: "Description for AppError.unknown")
        }

        static func unexpected(_ detail: String) -> String {
            String(localized: "error.unexpected",
                   defaultValue: "Something unexpected happened: \(detail)",
                   comment: "Description for AppError.unexpected; %@ is a developer detail")
        }

        static func invalidInput(_ field: String) -> String {
            String(localized: "error.invalidInput",
                   defaultValue: "The value provided for \(field) is not valid.",
                   comment: "Description for AppError.invalidInput; %@ is the field name")
        }

        static func notFound(_ resource: String) -> String {
            String(localized: "error.notFound",
                   defaultValue: "We couldn’t find \(resource).",
                   comment: "Description for AppError.notFound; %@ is the resource name")
        }

        static func persistence(_ detail: String) -> String {
            String(localized: "error.persistence",
                   defaultValue: "Saving your data failed: \(detail)",
                   comment: "Description for AppError.persistence; %@ is a developer detail")
        }

        static var permissionDenied: String {
            String(localized: "error.permissionDenied",
                   defaultValue: "You don’t have permission to do that.",
                   comment: "Description for AppError.permissionDenied")
        }

        static var menuBarItemActivationFailed: String {
            String(localized: "error.menuBarItemActivationFailed",
                   defaultValue: "iMenu couldn’t open that menu bar item.",
                   comment: "Description for AppError.menuBarItemActivationFailed")
        }

        static var menuBarItemPlacementFailed: String {
            String(localized: "error.menuBarItemPlacementFailed",
                   defaultValue: "iMenu couldn’t move that menu bar item.",
                   comment: "Description for AppError.menuBarItemPlacementFailed")
        }

        static var recoveryGeneric: String {
            String(localized: "error.recovery.generic",
                   defaultValue: "Please try again.",
                   comment: "Generic recovery suggestion")
        }

        static var recoveryPermission: String {
            String(localized: "error.recovery.permission",
                   defaultValue: "Grant the required permission in System Settings and try again.",
                   comment: "Recovery suggestion for a permission error")
        }

        static var recoveryInvalidInput: String {
            String(localized: "error.recovery.invalidInput",
                   defaultValue: "Check the highlighted field and try again.",
                   comment: "Recovery suggestion for an invalid-input error")
        }
    }
}
