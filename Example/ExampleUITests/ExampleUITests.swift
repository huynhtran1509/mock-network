//
//  ExampleUITests.swift
//  ExampleUITests
//
//  Created by Ian Terrell on 8/18/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import XCTest
import NetworkFixtures


class ExampleUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        let base = #file.replacingOccurrences(of: "ExampleUITests.swift", with: "fixtures/")

        let fixtures: [Fixture] = [
            try! Fixture(regex: "stripe", type: .file(path: base + "stripe.xml")),
            ]

        continueAfterFailure = false

        let app = XCUIApplication()
        MockNetwork.load(fixtures: fixtures, in: &app.launchEnvironment)
        app.launch()
    }

    func testExample() {
        let textField = XCUIApplication().textFields["stripe response"]
        XCTAssertEqual("in ur codez", textField.value as? String)
    }
    
}
