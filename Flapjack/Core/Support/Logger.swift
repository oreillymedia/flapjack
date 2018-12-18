//
//  Logger.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/17/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import os

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

public final class Logger: NSObject {
    public static var logLevel: LoggerLevel = .debug
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

    public static func debug(_ object: CustomStringConvertible, isPrivate: Bool = true) {
        logLn(.debug, with: object, isPrivate: isPrivate)
    }
    public static func info(_ object: CustomStringConvertible) {
        logLn(.info, with: object, isPrivate: false)
    }
    public static func error(_ object: CustomStringConvertible) {
        logLn(.error, with: object, isPrivate: false)
    }
}
