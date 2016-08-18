//
//  TestHelpers.swift
//  Salix
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

class TestBundleClass {
    
}

func newTmpFile() -> URL {
    let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
    return tmpDir.appendingPathComponent(UUID().uuidString)
}

func fileNamed(_ name: String, ofType type: String) -> Data? {
    let bundle = Bundle(for: TestBundleClass.self)
    if let path = bundle.path(forResource: name, ofType: type) {
        return (try? Data(contentsOf: URL(fileURLWithPath: path)))
    }
    return nil
}

func urlForFileNamed(_ name: String, ofType type: String) -> URL? {
    let bundle = Bundle(for: TestBundleClass.self)
    if let path = bundle.path(forResource: name, ofType: type) {
        return URL(fileURLWithPath: path)
    }
    return nil
}
