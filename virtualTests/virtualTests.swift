//
//  virtualTests.swift
//  virtualTests
//
//  Created by Matthew Rocco on 12/17/15.
//  Copyright © 2015 Matthew Rocco. All rights reserved.
//

import MapKit
import XCTest
@testable import virtual

class virtualTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPin() {
        
        let location = CLLocationCoordinate2D(latitude: 100.0, longitude: 100.0)
        let pin = Pin(coordinate: location)
        XCTAssertEqual(100.0, pin.pin().coordinate.latitude)
        XCTAssertEqual(100.0, pin.pin().coordinate.longitude)
    }
    
    func testPhoto() {
    }
}
