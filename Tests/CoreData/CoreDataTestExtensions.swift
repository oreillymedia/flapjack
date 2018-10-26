//
//  CoreDataTestExtensions.swift
//  Flapjack+CoreData
//
//  Created by Ben Kreeger on 10/26/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    var resourceBundle: Bundle! {
        let bundle = Bundle(for: type(of: self))
        let bundleURL = bundle.url(forResource: "FlapjackCoreDataTests", withExtension: "bundle")!
        return Bundle(url: bundleURL)!
    }
}
