//
//  XMLPushParserTests.swift
//  Salix
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import XCTest
@testable import XMLPushParser

class XMLPushParserTests: XCTestCase {
    class Document: SAXParsable {
        required init() {}
        enum Element: String {
            case catalog
        }
        
        var catalog: Catalog?
        
        func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
            return .handleWithChild(Catalog())
        }
        
        func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) {
            catalog = child as? Catalog
        }
    }
    
    class Catalog: SAXParsable {
        required init() {}
        enum Element: String {
            case book
        }
        
        var books = [Book]()
        
        func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
            guard Element(rawValue: localName) != nil else {
                return .ignore
            }
            
            let book = Book()
            book.id = attributes["id"]!.value
            return .handleWithChild(book)
        }
        
        func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) {
            guard let book = child as? Book else {
                return
            }
            
            books.append(book)
        }
        
        func flatCatalog() -> [[String]] {
            return books.map({ book in
                return [book.id!, book.author!, book.title!]
            })
        }
    }
    
    class Book: SAXParsable {
        required init() {}
        enum Element: String {
            case author
            case title
            
            init?(prefix: String?, URI: String?, localName: String) {
                self.init(rawValue: localName)
            }
        }
        
        var id: String?
        var author: String?
        var title: String?
        
        func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
            guard let element = Element(rawValue: localName) else {
                return .ignore
            }
            
            switch element {
            case .author: fallthrough
            case .title:
                return .handleAsData
            }
        }
        
        func endDataElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute], contents: Data) {
            guard let element = Element(prefix: prefix, URI: URI, localName: localName) else {
                return
            }
            
            switch element {
            case .author:
                author = NSString(data: contents, encoding: String.Encoding.utf8.rawValue) as String?
            case .title:
                title = NSString(data: contents, encoding: String.Encoding.utf8.rawValue) as String?
            }
        }
    }

    
    func testCatalogParse() {
        let parser = XMLPushParser<Document>()
        do {
            let expected: [[String]] = [
                ["bk101", "Gambardella, Matthew", "XML Developer's Guide"],
                ["bk102", "Ralls, Kim", "Midnight Rain"],
                ["bk103", "Corets, Eva", "Maeve Ascendant"],
                ["bk104", "Corets, Eva", "Oberon's Legacy"],
                ["bk105", "Corets, Eva", "The Sundered Grail"],
                ["bk106", "Randall, Cynthia", "Lover Birds"],
                ["bk107", "Thurman, Paula", "Splish Splash"],
                ["bk108", "Knorr, Stefan", "Creepy Crawlies"],
                ["bk109", "Kress, Peter", "Paradox Lost"],
                ["bk110", "O'Brien, Tim", "Microsoft .NET: The Programming Bible"],
                ["bk111", "O'Brien, Tim", "MSXML3: A Comprehensive Guide"],
                ["bk112", "Galos, Mike", "Visual Studio 7: A Comprehensive Guide"],
            ]
            guard let catalog = try parser.parse(fileNamed("books", ofType: "xml")!).catalog else {
                XCTFail("should have a catalog")
                return
            }
            XCTAssert(expected.elementsEqual(catalog.flatCatalog(), by: { $0 == $1 }))
        } catch {
            XCTFail("should not throw \(error)")
        }
    }
    
    func testBrokenParse() {
        let parser = XMLPushParser<Catalog>()
        do {
            try _ = parser.parse(fileNamed("broken-books", ofType: "xml")!)
        } catch PushSaxParserErrorCode.libXML2Error(let message) {
            XCTAssert(message.characters.count != 0)
            return
        } catch {
            XCTFail("should have thrown the appropriate NSError")
        }
        XCTFail("should throw")
    }
}
