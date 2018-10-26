//
//  DataContextErrorTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 10/26/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Flapjack

class DataContextErrorTests: XCTestCase {
    func testPreparationError() {
        let nserror = NSError(domain: "Domain", code: 0, userInfo: nil)
        XCTAssertFalse(DataContextError.saveError(nserror).description.isEmpty)
        XCTAssertFalse(DataContextError.saveError(nserror).localizedDescription.isEmpty)
    }
}
