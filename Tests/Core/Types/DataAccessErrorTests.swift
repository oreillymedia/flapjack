//
//  DataAccessErrorTests.swift
//  Flapjack
//
//  Created by Ben Kreeger on 9/12/18.
//  Copyright © 2018 O'Reilly Media, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Flapjack

class DataAccessErrorTests: XCTestCase {
    func testPreparationError() {
        let nserror = NSError(domain: "Domain", code: 0, userInfo: nil)
        XCTAssertFalse(DataAccessError.preparationError(nserror).description.isEmpty)
        XCTAssertFalse(DataAccessError.preparationError(nserror).localizedDescription.isEmpty)
    }
}
