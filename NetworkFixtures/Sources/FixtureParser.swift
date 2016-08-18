//
//  FixtureParser.swift
//  iOS
//
//  Created by Ian Terrell on 8/17/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import Foundation
import XMLPushParser

extension MockResponse {
    init(fileURL: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            fatalError("Error reading fixture file: \(error)")
        }
        do {
            let parser = try XMLPushParser<FixtureXML.Parser>().parse(data)
            try self.init(parser: parser, url: fileURL)
        } catch {
            fatalError("Error parsing XML: \(error)")
        }
    }

    init(parser: FixtureXML.Parser, url: URL) throws {
        guard let parser = parser.children[.session]?.first as? SessionParser else {
            throw FixtureXML.ParseError.sessionIsRequired
        }
        try self.init(parser: parser, url: url)
    }

    private init(parser: SessionParser, url: URL) throws {
        guard let transactionParser = parser.transaction else {
            throw SessionParser.ParseError.transactionIsRequired
        }
        try self.init(parser: transactionParser, url: url)
    }

    private init(parser: TransactionParser, url: URL) throws {
        guard let responseParser = parser.response else {
            throw TransactionParser.ParseError.responseIsRequired
        }
        guard let httpVersion = parser.httpVersion else {
            throw TransactionParser.ParseError.httpVersionIsRequired
        }
        try self.init(parser: responseParser, url: url, httpVersion: httpVersion)
    }

    private init(parser: ResponseXML.Parser, url: URL, httpVersion: String) throws {
        guard let statusCode = parser.statusCode else {
            throw ResponseXML.ParseError.statusCodeIsRequired
        }

        guard let bodyElement = parser.datum(.body) else {
            throw ResponseXML.ParseError.bodyIsRequired
        }
        let bodyData: Data?
        if bodyElement.attributes["encoding"]?.value == "base64" {
            bodyData = Data(base64Encoded: bodyElement.value)
        } else {
            bodyData = bodyElement.value.data(using: .utf8)
        }
        guard let body = bodyData else {
            throw ResponseXML.ParseError.bodyIsMalformed
        }

        guard let parser = parser.children[.headers]?.first as? HeadersXML.Parser else {
            throw ResponseXML.ParseError.headersAreRequired
        }

        var headers: [String: String] = [:]
        for (element, parsers) in parser.children {
            guard case .header = element else {
                continue
            }
            for parser in parsers.flatMap({ $0 as? HeaderXML.Parser }) {
                guard let name = parser.datum(.name)?.value else {
                    throw HeaderXML.ParseError.nameIsRequired
                }
                guard let value = parser.datum(.value)?.value else {
                    throw HeaderXML.ParseError.valueIsRequired
                }
                headers[name] = value
            }
        }

        self.url = url
        self.statusCode = statusCode
        self.httpVersion = httpVersion
        self.headers = headers
        self.body = body
    }
}

enum FixtureXML {
    enum ParseError: Error {
        case sessionIsRequired
    }

    enum ChildElement: String, ChildXMLElement {
        case session = "charles-session"

        init?(prefix: String?, URI: String?, localName: String) {
            self.init(rawValue: localName)
        }

        func type() -> SAXParsable.Type {
            return SessionParser.self
        }
    }

    final class Parser: XMLSAXElementParser<XMLElementsNone, ChildElement> {
        required init() {}
    }
}

private class SessionParser: SAXParsable {
    enum ParseError: Error {
        case transactionIsRequired
    }

    required init() {}
    var transaction: TransactionParser?

    func startElement(_ prefix: String?, URI: String?,
                      localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
        switch localName {
        case "transaction":
            let parser = TransactionParser()
            parser.httpVersion = attributes["protocolVersion"]?.value
            return .handleWithChild(parser)
        default:
            return .ignore
        }

    }

    func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) {
        transaction = child as? TransactionParser
    }
}

private class TransactionParser: SAXParsable {
    required init() {}

    enum ParseError: Error {
        case responseIsRequired
        case httpVersionIsRequired
    }

    var httpVersion: String?
    var response: ResponseXML.Parser?

    func startElement(_ prefix: String?, URI: String?,
                      localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
        switch localName {
        case "response":
            let parser = ResponseXML.Parser()
            if let attr = attributes["status"]?.value {
                parser.statusCode = Int(attr)
            }
            return .handleWithChild(parser)
        default:
            return .ignore
        }
    }

    func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) {
        response = child as? ResponseXML.Parser
    }
}

private enum ResponseXML {
    enum ParseError: Error {
        case statusCodeIsRequired
        case bodyIsRequired
        case bodyIsMalformed
        case headersAreRequired
    }

    enum DataElement: String, XMLElement {
        case body

        init?(prefix: String?, URI: String?, localName: String) {
            self.init(rawValue: localName)
        }
    }

    enum ChildElement: String, ChildXMLElement {
        case headers

        init?(prefix: String?, URI: String?, localName: String) {
            self.init(rawValue: localName)
        }

        func type() -> SAXParsable.Type {
            return HeadersXML.Parser.self
        }
    }

    final class Parser: XMLSAXElementParser<DataElement, ChildElement> {
        required init() {}
        var statusCode: Int?
    }
}

private enum HeadersXML {
    enum ParseError: Error {
    }

    enum ChildElement: String, ChildXMLElement {
        case header

        init?(prefix: String?, URI: String?, localName: String) {
            self.init(rawValue: localName)
        }

        func type() -> SAXParsable.Type {
            return HeaderXML.Parser.self
        }
    }

    final class Parser: XMLSAXElementParser<XMLElementsNone, ChildElement> {
        required init() {}
    }
}

private enum HeaderXML {
    enum ParseError: Error {
        case nameIsRequired
        case valueIsRequired
    }

    enum DataElement: String, XMLElement {
        case name
        case value

        init?(prefix: String?, URI: String?, localName: String) {
            self.init(rawValue: localName)
        }
    }

    final class Parser: XMLSAXElementParser<DataElement, XMLElementsNone> {
        required init() {}
    }
}
