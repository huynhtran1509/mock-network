//
//  Fixture.swift
//  iOS
//
//  Created by Ian Terrell on 8/17/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation

public struct Fixture {
    public let regex: NSRegularExpression
    public let type: FixtureType
    public var usage: Usage

    public init(regex: String, type: FixtureType, use usage: Usage = .always) throws {
        do {
            self.regex = try NSRegularExpression(pattern: regex, options: [])
        } catch {
            throw FixtureError.regexIsInvalid(regex, error)
        }
        if case .nTimes(let i) = usage, i <= 1 {
            throw FixtureError.usageNTimesMustBeGreaterThanZero(i)
        }
        self.type = type
        self.usage = usage
    }

    public init(json: [String: String]) throws {
        guard let regex = json["regex"] else {
            throw FixtureError.regexIsRequired
        }
        do {
            self.regex = try NSRegularExpression(pattern: regex, options: [])
        } catch {
            throw FixtureError.regexIsInvalid(regex, error)
        }

        guard let type = json["type"] else {
            throw FixtureError.typeIsRequired
        }
        switch type {
        case "file":
            guard let path = json["path"] else {
                throw FixtureError.pathIsRequiredForTypeFile
            }
            self.type = .file(path: path)
        case "error":
            guard let errorString = json["error"] else {
                throw FixtureError.errorIsRequiredForTypeError
            }
            guard let error = MockError(rawValue: errorString) else {
                throw FixtureError.errorIsNotAvailable(errorString)
            }
            self.type = .error(error)
        default:
            throw FixtureError.invalidType(type)
        }

        guard let usage = json["usage"] else {
            throw FixtureError.usageIsRequired
        }
        switch usage {
        case "always":
            self.usage = .always
        case "once":
            self.usage = .once
        default:
            guard let i = Int(usage) else {
                throw FixtureError.usageIsInvalid(usage)
            }
            self.usage = .nTimes(i)
        }
    }

    func jsonObject() -> [String: String] {
        var output = ["regex": regex.pattern]
        switch type {
        case .file(let path):
            output["type"] = "file"
            output["path"] = path
        case .error(let error):
            output["type"] = "error"
            output["error"] = error.rawValue
        }
        switch usage {
        case .always:
            output["usage"] = "always"
        case .once:
            output["usage"] = "once"
        case .nTimes(let i):
            output["usage"] = "\(i)"
        }
        return output
    }

    public enum FixtureError: Error {
        case regexIsRequired
        case regexIsInvalid(String, Error)
        case typeIsRequired
        case invalidType(String)
        case pathIsRequiredForTypeFile
        case errorIsRequiredForTypeError
        case errorIsNotAvailable(String)
        case usageIsRequired
        case usageNTimesMustBeGreaterThanZero(Int)
        case usageIsInvalid(String)
    }

    public enum FixtureType {
        case file(path: String)
        case error(MockError)
    }

    public enum Usage {
        case always
        case once
        case nTimes(Int)
    }

    public enum MockError: String {
        case offline
    }
}

extension Fixture: Equatable {
    public static func ==(lhs: Fixture, rhs: Fixture) -> Bool {
        return lhs.regex == rhs.regex && lhs.type == rhs.type && lhs.usage == rhs.usage
    }
}

extension Fixture.FixtureType: Equatable {
    public static func ==(lhs: Fixture.FixtureType, rhs: Fixture.FixtureType) -> Bool {
        switch (lhs, rhs) {
        case (.file(let lhsPath), .file(let rhsPath)):
            return lhsPath == rhsPath
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

extension Fixture.MockError: Equatable {
    public static func ==(lhs: Fixture.MockError, rhs: Fixture.MockError) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline):
            return true
        }
    }
}

extension Fixture.Usage: Equatable {
    public static func ==(lhs: Fixture.Usage, rhs: Fixture.Usage) -> Bool {
        switch (lhs, rhs) {
        case (.always, .always):
            return true
        case (.once, .once):
            return true
        case (.nTimes(let i), .nTimes(let j)):
            return i == j
        default:
            return false
        }
    }
}

extension Collection where Iterator.Element == Fixture {
    func toJSON() -> String {
        let mapped = self.map { $0.jsonObject() }
        guard let jsonObject = try? JSONSerialization.data(withJSONObject: mapped, options: []),
            let json = String(data: jsonObject, encoding: .utf8)
            else {
                fatalError("Could not create JSON")
        }
        return json
    }

    func firstMatching(url: String) -> (Fixture, Int)? {
        for (i, fixture) in self.enumerated() {
            if fixture.regex.numberOfMatches(in: url, options: [], range: NSRange(0..<url.characters.count)) > 0 {
                return (fixture, i)
            }
        }
        return nil
    }
}
