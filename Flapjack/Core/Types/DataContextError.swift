//
//  DataContextError.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

/**
 Encapsulates error state when thrown by a `DataContext`.
 */
public enum DataContextError: LocalizedError, CustomStringConvertible {
    /// Indicates an error during a save/persist action. Includes the underlying framework error thrown.
    case saveError(Error)
    /// Indicates an error when trying to cast fetched results. Includes the intended type, and the received result.
    case fetchTypeError(String, Any?)

    public var description: String {
        switch self {
        case .saveError(let error):
            return (error as NSError).description
        case .fetchTypeError(let typeName, let received):
            return "DataContextError.fetchTypeError: expected fetch of type \(typeName); got \(String(describing: received))"
        }
    }

    public var localizedDescription: String {
        switch self {
        case .saveError(let error):
            return (error as NSError).localizedDescription
        case .fetchTypeError(let typeName, let received):
            return "DataContextError.fetchTypeError: expected fetch of type \(typeName); got \(String(describing: received))"
        }
    }

    public var errorDescription: String? {
        return description
    }

    public var recoverySuggestion: String? {
        switch self {
        case .saveError(let error):
            return (error as NSError).localizedRecoverySuggestion
        case .fetchTypeError:
            return "Check your requested type information and try again; make sure your type conforms to the necessary protocol"
        }
    }
}
