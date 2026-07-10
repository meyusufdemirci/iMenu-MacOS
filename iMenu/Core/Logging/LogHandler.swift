//
//  LogHandler.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// The output destination for log records.
///
/// `AppLogger` owns *what* and *whether* to log; a `LogHandler` owns *where*
/// the record ends up. This seam is what makes logging testable — production
/// uses `OSLogHandler`, tests inject an in-memory spy.
protocol LogHandler {
    func handle(_ entry: LogEntry)
}
