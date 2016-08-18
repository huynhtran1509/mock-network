//
//  XMLElementParserTests.swift
//  Salix
//
//  Created by Ian Terrell on 7/17/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import XCTest
@testable import XMLPushParser

class XMLPushParserElementParserTests: XCTestCase {
    
    class Document: SAXParsable {
        required init() {}
        enum Element: String {
            case catalog
        }
        
        var catalog: Catalog?
        
        func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
            return .handleWithChild(Catalog.XML.Parsable())
        }
        
        func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) {
            catalog = Catalog(parser: child as! Catalog.XML.Parsable)
        }
    }
    
    class Catalog {
        var owners = [String]()
        var books = [Book]()
        
        func flatCatalog() -> [[String]] {
            return books.map({ book in
                return [book.author, book.title]
            })
        }
        
        init(parser: XML.Parsable) {
            for (element, values) in parser.data {
                for datum in values {
                    switch element {
                    case .owner:
                        self.owners.append(datum.value)
                    }
                }
            }
            for (element, items) in parser.children {
                for item in items {
                    switch element {
                    case .book:
                        self.books.append(Book(parser: item as! Book.XML.Parser))
                    }
                }
            }
        }
        
        class XML {
            enum DataElement: String, XMLElementStringEnum {
                case owner
            }
            
            enum ChildElement: String, ChildXMLElement, XMLElementStringEnum {
                case book
                
                func type() -> SAXParsable.Type {
                    return Book.XML.Parser.self
                }
            }
            
            class Parsable: XMLSAXElementParser<DataElement, ChildElement> {
                required init() {}
                var catalog: Catalog {
                    get {
                        return Catalog(parser: self)
                    }
                }
            }
        }
    }
    
    class Book {
        var author: String
        var title: String
        
        init(parser: XML.Parser) {
            author = parser.datum(.author)!.value
            title = parser.datum(.title)!.value
        }
        
        class XML {
            enum DataElement: String, XMLElementStringEnum {
                case author
                case title
            }
            
            class Parser: XMLSAXElementParser<DataElement,XMLElementsNone> {
                required init() {}
            }
        }
    }
    
    func testCatalogParse() {
        let parser = XMLPushParser<Document>()
        do {
            guard let catalog = try parser.parse(fileNamed("books", ofType: "xml")!).catalog else {
                XCTFail("should have a catalog")
                return
            }
            let expected = [
                ["Gambardella, Matthew", "XML Developer's Guide"],
                ["Ralls, Kim", "Midnight Rain"],
                ["Corets, Eva", "Maeve Ascendant"],
                ["Corets, Eva", "Oberon's Legacy"],
                ["Corets, Eva", "The Sundered Grail"],
                ["Randall, Cynthia", "Lover Birds"],
                ["Thurman, Paula", "Splish Splash"],
                ["Knorr, Stefan", "Creepy Crawlies"],
                ["Kress, Peter", "Paradox Lost"],
                ["O'Brien, Tim", "Microsoft .NET: The Programming Bible"],
                ["O'Brien, Tim", "MSXML3: A Comprehensive Guide"],
                ["Galos, Mike", "Visual Studio 7: A Comprehensive Guide"],
            ]
            XCTAssert(expected.elementsEqual(catalog.flatCatalog(), by: { $0 == $1 }))
        } catch {
            XCTFail("should not throw, got: \(error)")
        }
        
        
    }
    
    func testBrokenParse() {
        let parser = XMLPushParser<Catalog.XML.Parsable>()
        do {
            try _ = parser.parse(fileNamed("broken-books", ofType: "xml")!)
        } catch PushSaxParserErrorCode.libXML2Error(let message) {
            XCTAssertEqual("Extra content at the end of the document\n", message)
            return
        } catch {
            XCTFail("should have thrown PushSaxParserErrorCode.LibXML2Error")
        }
        XCTFail("should throw")
    }
    
    func testMultipleDataElements() {
        let parser = XMLPushParser<Document>()
        do {
            guard let catalog = try parser.parse(fileNamed("repeat-owner", ofType: "xml")!).catalog else {
                XCTFail("should have a catalog")
                return
            }
            XCTAssertEqual(["a", "b", "c"], catalog.owners)
        } catch {
            XCTFail("should not throw")
        }
    }
}

