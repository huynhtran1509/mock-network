//
//  MockNetwork.swift
//  iOS
//
//  Created by Ian Terrell on 8/17/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation

public let mockNetworkEnvironmentVariable = "MOCK_NETWORK_FIXTURES"

public class MockNetwork: URLProtocol {
    public class func register() {
        if ProcessInfo().environment[mockNetworkEnvironmentVariable] != nil {
            URLProtocol.registerClass(MockNetwork.self)
        }
    }

    public class func load(fixtures: [Fixture], in environment: inout [String:String]) {
        environment[mockNetworkEnvironmentVariable] = fixtures.toJSON()
    }

    static var fixtures: [Fixture] = {
        guard let jsonString = ProcessInfo().environment[mockNetworkEnvironmentVariable] else {
            return []
        }
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Could not make data from JSON string")
        }
        let jsonObject: [[String:String]]
        do {
            guard let object = try JSONSerialization.jsonObject(with: jsonData,
                                                                options: .allowFragments) as? [[String:String]] else {
                fatalError("JSON of wrong type")
            }
            jsonObject = object
        } catch {
            fatalError("Could not properly parse JSON: \(error)")
        }
        do {
            return try jsonObject.map({ try Fixture(json: $0) })
        } catch {
            fatalError("Could not reconstitute fixtures: \(error)")
        }
    }()

    override public class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else {
            return false
        }
        return fixtures.firstMatching(url: url) != nil
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        guard let url = request.url?.absoluteString,
            let (fixture, index) = MockNetwork.fixtures.firstMatching(url: url)
        else {
            fatalError()
        }

        guard case .file(let path) = fixture.type else {
            fatalError("Errors are not supported yet")
        }

        switch fixture.usage {
        case .once:
            MockNetwork.fixtures.remove(at: index)
        case .nTimes(var i):
            i -= 1
            if i <= 0 {
                MockNetwork.fixtures.remove(at: index)
            } else {
                MockNetwork.fixtures[index].usage = .nTimes(i)
            }
        default:
            break
        }

        let file = URL(fileURLWithPath: path)
        let mock = MockResponse(fileURL: file)

        client?.urlProtocol(self, didLoad: mock.body)
        client?.urlProtocol(self, didReceive: mock.httpURLResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override public func stopLoading() {}
}

