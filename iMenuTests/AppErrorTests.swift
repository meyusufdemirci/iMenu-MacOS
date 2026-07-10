//
//  AppErrorTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// Tests for the global `AppError` type.
///
/// These are written first (TDD): they describe the contract that
/// `AppError` must satisfy before the type is implemented.
struct AppErrorTests {

    @Test func unknownProducesStableDescription() {
        #expect(AppError.unknown.errorDescription == "An unknown error occurred.")
    }

    @Test func invalidInputMentionsTheField() {
        let error = AppError.invalidInput(field: "email")
        #expect(error.errorDescription?.contains("email") == true)
    }

    @Test func notFoundMentionsTheResource() {
        let error = AppError.notFound(resource: "Menu")
        #expect(error.errorDescription?.contains("Menu") == true)
    }

    @Test func unexpectedMentionsTheDetail() {
        let error = AppError.unexpected("disk full")
        #expect(error.errorDescription?.contains("disk full") == true)
    }

    @Test func everyCaseProvidesANonEmptyDescription() {
        let errors: [AppError] = [
            .unknown,
            .unexpected("x"),
            .invalidInput(field: "f"),
            .notFound(resource: "r"),
            .persistence("p"),
            .permissionDenied,
            .menuBarItemActivationFailed
        ]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func everyCaseProvidesARecoverySuggestion() {
        let errors: [AppError] = [
            .unknown,
            .unexpected("x"),
            .invalidInput(field: "f"),
            .notFound(resource: "r"),
            .persistence("p"),
            .permissionDenied,
            .menuBarItemActivationFailed
        ]

        for error in errors {
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
    }

    @Test func isEquatable() {
        #expect(AppError.unknown == AppError.unknown)
        #expect(AppError.invalidInput(field: "a") == AppError.invalidInput(field: "a"))
        #expect(AppError.invalidInput(field: "a") != AppError.invalidInput(field: "b"))
        #expect(AppError.unknown != AppError.permissionDenied)
    }
}
