//
//  virtualUITests.swift
//  virtualUITests
//
//  Created by Matthew Rocco on 12/17/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import XCTest

class virtualUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        XCUIApplication().childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element.childrenMatchingType(.Map).element.pressForDuration(0.6);
    }
}
