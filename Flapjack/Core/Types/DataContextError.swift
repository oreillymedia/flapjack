//
//  DataContextError.swift
//  Flapjack
//
//  Created by Ben Kreeger on 11/4/17.
//  Copyright © 2017 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public enum DataContextError: LocalizedError, CustomStringConvertible {
    case saveError(Error)
    
    public var description: String {
        switch self {
        case .saveError(let error):
            return (error as NSError).description
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .saveError(let error):
            return (error as NSError).localizedDescription
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return (error as NSError).description
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .saveError(let error):
            return (error as NSError).localizedRecoverySuggestion
        }
    }
}
