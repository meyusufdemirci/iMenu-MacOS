//
//  LoggingTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// A test double that captures every `LogEntry` it receives so tests can
/// assert on what the logger produced without touching the unified log.
private final class SpyLogHandler: LogHandler {
    private(set) var entries: [LogEntry] = []

    func handle(_ entry: LogEntry) {
        entries.append(entry)
    }
}

struct LogLevelTests {

    @Test func levelsAreOrderedBySeverity() {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
    }
}

struct AppLoggerTests {

    @Test func infoMessageIsForwardedToTheHandler() {
        let spy = SpyLogHandler()
        let logger = AppLogger(handler: spy, minimumLevel: .debug)

        logger.info("Home screen appeared", category: .ui)

        #expect(spy.entries.count == 1)
        let entry = spy.entries.first
        #expect(entry?.level == .info)
        #expect(entry?.message == "Home screen appeared")
        #expect(entry?.category == LogCategory.ui.rawValue)
    }

    @Test func messagesBelowTheMinimumLevelAreDropped() {
        let spy = SpyLogHandler()
        let logger = AppLogger(handler: spy, minimumLevel: .warning)

        logger.debug("noise")
        logger.info("also noise")
        #expect(spy.entries.isEmpty)

        logger.warning("kept")
        logger.error("kept too")
        #expect(spy.entries.count == 2)
        #expect(spy.entries.map(\.level) == [.warning, .error])
    }

    @Test func sourceLocationIsCaptured() {
        let spy = SpyLogHandler()
        let logger = AppLogger(handler: spy)

        logger.info("with location")

        let entry = spy.entries.first
        #expect(entry?.function.isEmpty == false)
        #expect((entry?.line ?? 0) > 0)
        #expect(entry?.file.isEmpty == false)
    }

    @Test func defaultCategoryIsGeneral() {
        let spy = SpyLogHandler()
        let logger = AppLogger(handler: spy)

        logger.info("no category given")

        #expect(spy.entries.first?.category == LogCategory.general.rawValue)
    }
}
