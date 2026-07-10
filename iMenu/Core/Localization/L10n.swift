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
