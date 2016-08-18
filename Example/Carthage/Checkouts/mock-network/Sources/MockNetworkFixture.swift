//
//  MockNetworkFixture.swift
//  iOS
//
//  Created by Ian Terrell on 8/17/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation

let mockNetworkEnvironmentVariable = "MOCK_NETWORK_FIXTURES"

struct MockNetworkFixture {
    let regex: NSRegularExpression
    let type: FixtureType

    init(regex: String, type: FixtureType) throws {
        do {
            self.regex = try NSRegularExpression(pattern: regex, options: [])
        } catch {
            throw JSONError.regexIsInvalid(regex, error)
        }
        self.type = type
    }

    init(json: [String: String]) throws {
        guard let regex = json["regex"] else {
            throw JSONError.regexIsRequired
        }
        do {
            self.regex = try NSRegularExpression(pattern: regex, options: [])
        } catch {
            throw JSONError.regexIsInvalid(regex, error)
        }

        guard let type = json["type"] else {
            throw JSONError.typeIsRequired
        }
        switch type {
        case "file":
            guard let path = json["path"] else {
                throw JSONError.pathIsRequiredForTypeFile
            }
            self.type = .file(path: path)
        case "error":
            guard let errorString = json["error"] else {
                throw JSONError.errorIsRequiredForTypeError
            }
            guard let error = MockError(rawValue: errorString) else {
                throw JSONError.errorIsNotAvailable(errorString)
            }
            self.type = .error(error)
        default:
            throw JSONError.invalidType(type)
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
        return output
    }

    enum JSONError: Error {
        case regexIsRequired
        case regexIsInvalid(String, Error)
        case typeIsRequired
        case invalidType(String)
        case pathIsRequiredForTypeFile
        case errorIsRequiredForTypeError
        case errorIsNotAvailable(String)
    }

    enum FixtureType {
        case file(path: String)
        case error(MockError)
    }

    enum MockError: String {
        case offline
    }
}

extension Collection where Iterator.Element == MockNetworkFixture {
    func toJSON() -> String {
        let mapped = self.map { $0.jsonObject() }
        guard let jsonObject = try? JSONSerialization.data(withJSONObject: mapped, options: []),
            let json = String(data: jsonObject, encoding: .utf8)
            else {
                fatalError("Could not create JSON")
        }
        return json
    }

    func firstMatching(url: String) -> MockNetworkFixture? {
        for fixture in self {
            if fixture.regex.numberOfMatches(in: url, options: [], range: NSRange(0..<url.characters.count)) > 0 {
                return fixture
            }
        }
        return nil
    }
}
