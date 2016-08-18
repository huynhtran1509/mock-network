//
//  XMLConversions.swift
//  Salix
//
//  Created by Ian Terrell on 7/16/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import XCTest
@testable import XMLPushParser

class XMLConversionTests: XCTestCase {
    func data(_ string: String) -> Data {
        return string.data(using: String.Encoding.utf8)!
    }
    
    class Parsable: SAXParsable {
        required init() {}
    }
    let parsable = Parsable()
    
    func testStrings() {
        let cases = [
            "a",
            "b",
            "foo",
            "bar",
        ]
        for test in cases {
            XCTAssertEqual(test, parsable.stringFromXML(data(test)))
        }
    }
    
    func testInts() {
        let cases = [
            "1": 1,
            "2": 2,
            "-1": -1,
            "foo": 0,
            "bar": 0,
            "1.1": 0,
        ]
        for (str, int) in cases {
            XCTAssertEqual(int, parsable.intFromXMLString(str))
        }
        XCTAssertNil(parsable.intFromXMLString(nil))
    }

    func testBools() {
        let cases = [
            "1": true,
            "0": false,
            "t": true,
            "T": true,
            "true": true,
            "True": true,
            "TRUE": true,
            "f": false,
            "F": false,
            "false": false,
            "FALSE": false,
            "2": false,
            "foo": false,
            
        ]
        for (str, bool) in cases {
            XCTAssertEqual(bool, parsable.boolFromXMLString(str))
        }
        XCTAssertNil(parsable.boolFromXMLString(nil))
    }
}
