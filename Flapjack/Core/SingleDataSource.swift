//
//  SingleDataSource.swift
//  Flapjack
//
//  Created by Ben Kreeger on 2/15/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation

public protocol SingleDataSource {
    associatedtype ModelType

    var attributes: DataContext.Attributes { get }
    var object: ModelType? { get }
    var objectDidChange: ((ModelType?) -> Void)? { get set }

    func execute()
}
