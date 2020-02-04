//
//  UnitTestExampleTests.swift
//  UnitTestExampleTests
//
//  Created by Jose Alberto Ruíz-Carrillo González on 04/02/2020.
//  Copyright © 2020 JARCG. All rights reserved.
//

import XCTest
@testable import UnitTestExample

class UnitTestExampleTests: XCTestCase {
    func testSquareInt() {
        let value = 3
        let squaredValue = value.square()
        XCTAssertEqual(squaredValue, 9)
    }
    
    func testHelloWorld() {
        var helloWorld: String?
        XCTAssertNil(helloWorld)
        helloWorld = "Hello World"
        XCTAssertEqual(helloWorld, "Hello World")
    }
}
