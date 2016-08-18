//
//  XML.swift
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

public enum SAXStartElement {
    case ignore
    case handleAsData
    case handleWithChild(SAXParsable)
}

public protocol SAXParsable {
    init()
    func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement
    func endDataElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute], contents: Data)
    func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable)
}

public class XMLPushParser<T: SAXParsable>: LibXMLPushSAXParser {
    var root: T
    private var stack = [SAXParsableStackItem]()
    private var current: SAXParsable {
        return stack.last!.parseItem
    }
    
    private var level = 0
    
    private var buffer: NSMutableData?
    private var dataAttributes: [String:LibXMLAttribute]?
    
    private var ignoreElementsUntilLevel: Int?
    private var ignoringElements: Bool {
        guard ignoreElementsUntilLevel != nil else {
            return false
        }
        return level >= ignoreElementsUntilLevel!
    }
    
    required override public init() {
        root = T()
        stack.append(SAXParsableStackItem(root, level: level))
        super.init()
    }
    
    public func parse(_ data: Data) throws -> T {
        try super._parse(data)
        return root
    }
    
    public func parseData(_ data: Data) throws {
        try super._parseData(data)
    }
    
    public func finishParsing() throws -> T {
        try super._finishParsing()
        return root
    }
    
    override public func startElementWithPrefix(_ prefix: String?, uri URI: String?, localName: String, attributes: [String:LibXMLAttribute]) {
        level += 1

        if ignoringElements {
            return
        }
        
        switch current.startElement(prefix, URI: URI, localName: localName, attributes: attributes) {
        case .ignore:
            ignoreElementsUntilLevel = level
        case .handleAsData:
            buffer = NSMutableData()
            dataAttributes = attributes
        case .handleWithChild(let child):
            stack.append(SAXParsableStackItem(child, level: level))
        }
    }
    
    override public func endElementWithPrefix(_ prefix: String?, uri URI: String?, localName: String) {
        defer {
            if let ignoreLevel = ignoreElementsUntilLevel {
                if ignoreLevel == level {
                    ignoreElementsUntilLevel = nil
                }
            }
            level -= 1
        }
        
        if ignoringElements {
            return
        }
        
        if stack.last!.level == level {
            let child = stack.removeLast().parseItem
            current.endChildElement(prefix, URI: URI, localName: localName, child: child)
            return
        }
        
        current.endDataElement(prefix, URI: URI, localName: localName, attributes: dataAttributes!, contents: buffer! as Data)
        buffer = nil
        dataAttributes = nil
    }
    
    override public func charactersFound(_ characters: UnsafePointer<xmlChar>, length: Int) {
        buffer?.append(characters, length: length)
    }
}

private struct SAXParsableStackItem {
    let parseItem: SAXParsable
    let level: Int
    
    init(_ parseItem: SAXParsable, level: Int) {
        self.parseItem = parseItem
        self.level = level
    }
}

public extension SAXParsable {
    func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
        return .ignore
    }
    func endDataElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute], contents: Data) { }
    func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) { }
}

public extension SAXParsable {
    public func stringFromXML(_ data: Data) -> String {
        return Conversion.stringFromData(data)
    }
    
    public func intFromXMLString(_ string: String?) -> Int! {
        return Conversion.intFromString(string)
    }
    
    public func boolFromXMLString(_ string: String?) -> Bool! {
        return Conversion.boolFromString(string)
    }
}

public protocol XMLElement: Hashable {
    init?(prefix: String?, URI: String?, localName: String)
}

public protocol ChildXMLElement: XMLElement {
    func type() -> SAXParsable.Type
}

open class XMLSAXElementParser<DataElement:XMLElement, ChildElement:ChildXMLElement>: SAXParsable {
    required public init() {}
    
    public var data = [DataElement:[XMLDataElement]]()
    public var children = [ChildElement:[SAXParsable]]()
    
    public func startElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute]) -> SAXStartElement {
        if let _ = DataElement(prefix: prefix, URI: URI, localName: localName) {
            return .handleAsData
        }
        
        guard let childElement = ChildElement(prefix: prefix, URI: URI, localName: localName) else {
            return .ignore
        }
        
        return .handleWithChild(childElement.type().init())
    }
    
    public func endChildElement(_ prefix: String?, URI: String?, localName: String, child: SAXParsable) {
        guard let element = ChildElement(prefix: prefix, URI: URI, localName: localName) else {
            return
        }
        
        if children[element] == nil {
            children[element] = [SAXParsable]()
        }
        children[element]!.append(child)
    }
    
    public func endDataElement(_ prefix: String?, URI: String?, localName: String, attributes: [String:LibXMLAttribute], contents: Data) {
        guard let element = DataElement(prefix: prefix, URI: URI, localName: localName) else {
            return
        }
        if data[element] == nil {
            data[element] = [XMLDataElement]()
        }
        data[element]!.append(XMLDataElement(value: stringFromXML(contents), attributes: attributes))
    }
    
    public func datum(_ key: DataElement) -> XMLDataElement? {
        return data[key]?.first
    }
}

public struct XMLDataElement: Equatable {
    public let value: String
    public let attributes: [String:LibXMLAttribute]
    init(value: String, attributes: [String:LibXMLAttribute]) {
        self.value = value
        self.attributes = attributes
    }
    
    public var intValue: Int? {
        return Int(value)
    }
    
    public var boolValue: Bool? {
        if value == "True" {
            return true
        } else if value == "False" {
            return false
        } else {
            return nil
        }
    }
}

public func ==(lhs: XMLDataElement, rhs: XMLDataElement) -> Bool {
    return lhs.value == rhs.value &&
        Array<String>(lhs.attributes.keys) == Array<String>(rhs.attributes.keys) &&
        Array<LibXMLAttribute>(lhs.attributes.values) == Array<LibXMLAttribute>(rhs.attributes.values)
}

public struct XMLElementsNone: XMLElement, ChildXMLElement {
    public init?(prefix: String?, URI: String?, localName: String) {
        return nil
    }
    public func type() -> SAXParsable.Type {
        return XMLSAXElementParser<XMLElementsNone,XMLElementsNone>.self
    }
    public var hashValue = 0
}

public func ==(lhs: XMLElementsNone, rhs: XMLElementsNone) -> Bool {
    return false
}

public protocol XMLElementStringEnum: XMLElement {
    init?(rawValue: String)
}

public extension XMLElementStringEnum {
    init?(prefix: String?, URI: String?, localName: String) {
        self.init(rawValue: localName)
    }
}
