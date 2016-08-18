//
//  Response.swift
//  NetworkFixtures
//
//  Created by Ian Terrell on 8/18/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation

struct MockResponse {
    var url: URL
    var httpVersion: String
    var statusCode: Int
    var headers: [String:String]
    var body: Data

    var httpURLResponse: HTTPURLResponse {
        // Overwrite content length for easy manual editing of response body.
        var headers = self.headers
        headers["Content-Length"] = "\(body.count)"

        guard let response = HTTPURLResponse(url: url,
                                             statusCode: statusCode,
                                             httpVersion: httpVersion,
                                             headerFields: headers)
        else {
            fatalError("Error building HTTPURLResponse")
        }
        return response
    }
}
