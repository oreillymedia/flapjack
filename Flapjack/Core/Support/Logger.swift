//
//  Logger.swift
//  Flapjack
//
//  Created by Ben Kreeger on 5/17/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public enum LoggerLevel: Int, CustomStringConvertible {
    case verbose = 0
    case debug
    case info
    case warning
    case error
    case fatal
    
    public var description: String {
        switch self {
        case .verbose: return "Verbose"
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .fatal: return "Fatal"
        }
    }
}

public final class Logger: NSObject {
    static var logLevel: LoggerLevel = .debug
    
    private static var df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    public static func logLn(_ level: LoggerLevel, with message: String) {
        guard level.rawValue >= logLevel.rawValue else { return }
        
        let date = df.string(from: Date())
        print("\(date) [Flapjack | \(level)] > \(message)")
    }
    
    public static func logLn(_ level: LoggerLevel, with object: CustomStringConvertible) {
        logLn(level, with: object.description)
    }
    
    
    /// MARK: Convenience log methods
    public static func verbose(_ object: CustomStringConvertible) {
        logLn(.verbose, with: object)
    }
    public static func debug(_ object: CustomStringConvertible) {
        logLn(.debug, with: object)
    }
    public static func info(_ object: CustomStringConvertible) {
        logLn(.info, with: object)
    }
    public static func warning(_ object: CustomStringConvertible) {
        logLn(.warning, with: object)
    }
    public static func error(_ object: CustomStringConvertible) {
        logLn(.error, with: object)
    }
    public static func fatal(_ object: CustomStringConvertible) {
        logLn(.fatal, with: object)
    }
}
