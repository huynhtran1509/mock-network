//
//  Conversion.swift
//
//  Created by Ian Terrell on 7/22/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

public class Conversion {
    public static func stringFromData(_ data: Data) -> String {
        guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return ""
        }
        return string as String
    }
    
    public static func intFromString(_ string: String?) -> Int? {
        guard let string = string else {
            return nil
        }
        guard let int = Int(string) else {
            return 0
        }
        return int
    }
    
    public static func boolFromString(_ string: String?) -> Bool? {
        guard let string = string else {
            return nil
        }
        switch string.lowercased() {
        case "t", "true", "1":
            return true
        default:
            return false
        }
    }
}
