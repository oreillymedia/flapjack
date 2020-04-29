//
//  Logger.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/17/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import os.log

/// An enumeration describing the logging severity level used inside of Flapjack.
@available(iOS 10.0, *)
public enum LoggerLevel: Int, CustomStringConvertible {
    case debug = 0
    case info
    case error

    var osLogType: OSLogType {
        switch self {
        case .debug: return OSLogType.debug
        case .info: return OSLogType.info
        case .error: return OSLogType.error
        }
    }

    public var description: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .error: return "Error"
        }
    }
}


/// A logger object used for printing out relevant statements to `os_log`.
@available(iOS 10.0, *)
public final class Logger: NSObject {
    /// The minimum severity level to log; default is `.info`.
    public static var logLevel: LoggerLevel = .info
    /// The `OSLog` to which statements are delivered.
    public static var osLog = OSLog(subsystem: "com.oreillymedia.flapjack", category: "Flapjack")

    private static func logLn(_ level: LoggerLevel, with message: String, isPrivate: Bool) {
        guard level.rawValue >= logLevel.rawValue else {
            return
        }

        let staticString: StaticString = isPrivate ? "[%@] > %{private}@" : "[%@] > %{public}@"
        os_log(staticString, log: osLog, type: level.osLogType, level.description, message)
    }

    private static func logLn(_ level: LoggerLevel, with object: CustomStringConvertible, isPrivate: Bool) {
        logLn(level, with: object.description, isPrivate: isPrivate)
    }

    /**
     Convenience function for logging a debugging statement with a logging severity level of `.debug`.

     - parameter object: The string or string-convertible object to log.
     - parameter isPrivate: If `true`, the line will be redacted from the log when not attached to Xcode. Defaults to `true`.
     */
    public static func debug(_ object: CustomStringConvertible, isPrivate: Bool = true) {
        logLn(.debug, with: object, isPrivate: isPrivate)
    }

    /**
     Convenience function for logging a debugging statement with a logging severity level of `.info`.

     - parameter object: The string or string-convertible object to log.
     */
    public static func info(_ object: CustomStringConvertible) {
        logLn(.info, with: object, isPrivate: false)
    }

    /**
     Convenience function for logging a debugging statement with a logging severity level of `.error`.

     - parameter object: The string or string-convertible object to log.
     */
    public static func error(_ object: CustomStringConvertible) {
        logLn(.error, with: object, isPrivate: false)
    }
}
