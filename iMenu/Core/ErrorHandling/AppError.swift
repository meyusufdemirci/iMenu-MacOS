//
//  AppError.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// The single, app-wide error type.
///
/// Every failure that surfaces to the UI or the logger should be expressed as
/// an `AppError` (map lower-level errors — `URLError`, decoding failures, etc.
/// — into a case at the boundary). Conforming to `LocalizedError` means the
/// user-facing text is produced here and localized through `L10n`, and
/// `Equatable` makes errors easy to assert on in tests.
enum AppError: LocalizedError, Equatable {

    /// A failure with no more specific classification.
    case unknown

    /// An unexpected condition, with a developer-facing detail.
    case unexpected(String)

    /// User input failed validation for the named field.
    case invalidInput(field: String)

    /// A requested resource could not be found.
    case notFound(resource: String)

    /// A read/write against local storage failed.
    case persistence(String)

    /// The app lacks the permission required for an operation.
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .unknown:
            return L10n.Errors.unknown
        case .unexpected(let detail):
            return L10n.Errors.unexpected(detail)
        case .invalidInput(let field):
            return L10n.Errors.invalidInput(field)
        case .notFound(let resource):
            return L10n.Errors.notFound(resource)
        case .persistence(let detail):
            return L10n.Errors.persistence(detail)
        case .permissionDenied:
            return L10n.Errors.permissionDenied
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return L10n.Errors.recoveryPermission
        case .invalidInput:
            return L10n.Errors.recoveryInvalidInput
        default:
            return L10n.Errors.recoveryGeneric
        }
    }
}
