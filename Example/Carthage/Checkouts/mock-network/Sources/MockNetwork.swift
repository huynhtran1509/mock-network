//
//  MockNetwork.swift
//  iOS
//
//  Created by Ian Terrell on 8/17/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation
import XMLPushParser

class MockNetwork: URLProtocol {
    static let fixtures: [MockNetworkFixture] = {
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
            return try jsonObject.map({ try MockNetworkFixture(json: $0) })
        } catch {
            fatalError("Could not reconstitute fixtures: \(error)")
        }
    }()

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else {
            return false
        }
        return fixtures.firstMatching(url: url) != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url?.absoluteString,
            let fixture = MockNetwork.fixtures.firstMatching(url: url)
        else { fatalError() }

        guard case .file(let path) = fixture.type else {
            fatalError("Errors are not supported yet")
        }

        let file = URL(fileURLWithPath: path)
        let data: Data
        let parser: MockNetworkFixtureXML.Parser
        let mock: MockResponse

        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Error reading fixture file: \(error)")
        }
        do {
            parser = try XMLPushParser<MockNetworkFixtureXML.Parser>().parse(data)
            mock = try MockResponse(parser: parser)
        } catch {
            fatalError("Error parsing XML: \(error)")
        }

        var headers = mock.headers
        headers["Content-Length"] = "\(mock.body.count)"

        guard let response = HTTPURLResponse(url: file, statusCode: mock.statusCode,
                                             httpVersion: mock.httpVersion, headerFields: headers) else {
            fatalError("Error building HTTPURLResponse")
        }

        client?.urlProtocol(self, didLoad: mock.body)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

struct MockResponse {
    var httpVersion: String
    var statusCode: Int
    var headers: [String:String]
    var body: Data
}

