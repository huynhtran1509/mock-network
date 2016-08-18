//
//  XMLCallbackFunctions.swift
//
//  Created by Robert Thompson on 8/7/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

// Some convenience computed properties on LibXMLRawAttribute
extension LibXMLRawAttribute: Equatable {
    
    var valueLength: Int {
        guard let valueEnd = valueEnd, let valueStart = valueStart else { return 0 }
        return valueEnd - valueStart
    }
    
    var localNameString: String {
        guard let localName = localName else { return "" }
        return String(cString: localName)
    }
    
    var prefixString: String? {
        guard let prefix = prefix else { return nil }
        return String(cString: prefix)
    }
    
    var URIString: String? {
        guard let uri = uri else { return nil }
        return String(cString: uri)
    }
    
    var key: String {
        if let prefix = prefixString {
            return "\(prefix):\(localNameString)"
        }
        return localNameString
    }
    
    var attributeValue: String {
        guard let valueStart = valueStart else { return "" }
        return (NSString(bytes: valueStart, length: valueLength, encoding: String.Encoding.utf8.rawValue) as String?) ?? ""
    }
    
    static func getBufferPointerWithStart(_ start: UnsafeRawPointer?, length: Int) -> UnsafeBufferPointer<LibXMLRawAttribute> {
       return UnsafeBufferPointer<LibXMLRawAttribute>(start: start?.assumingMemoryBound(to: LibXMLRawAttribute.self), count: length)
    }
}

public func ==(lhs: LibXMLRawAttribute, rhs: LibXMLRawAttribute) -> Bool {
    return lhs.localName == rhs.localName &&
        lhs.prefix == rhs.prefix &&
        lhs.uri == rhs.uri &&
        lhs.valueStart == rhs.valueStart &&
        lhs.valueEnd == rhs.valueEnd
}

private extension LibXMLAttribute {
    init(rawValue: LibXMLRawAttribute) {
        self.prefix = rawValue.prefixString
        self.localName = rawValue.localNameString
        self.URI = rawValue.URIString
        self.value = rawValue.attributeValue
    }
}

private func XMLPushSAXParserStartElementSAX(_ ctx: UnsafeMutableRawPointer?,
                                             _ localname: UnsafePointer<xmlChar>?,
                                             _ prefix: UnsafePointer<xmlChar>?,
                                             _ uri: UnsafePointer<xmlChar>?,
                                             _ nb_namespaces: Int32,
                                             _ namespaces: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?,
                                             _ nb_attributes: Int32,
                                             _ nb_defaulted: Int32,
                                             _ attributes: UnsafeMutablePointer<UnsafePointer<xmlChar>?>?)
{
    let parser = getParser(ctx)

    guard let elementLocalName = getString(localname) else {
        parser.errorOccurred("No local name for element")
        return
    }
    
    let elementPrefix = getString(prefix)
    let elementURI = getString(uri)
    
    let attributesBuffer = LibXMLRawAttribute.getBufferPointerWithStart(attributes, length: Int(nb_attributes))
    var elementAttributes = Dictionary<String, LibXMLAttribute>()
    attributesBuffer.forEach {
        elementAttributes[$0.key] = LibXMLAttribute(rawValue: $0)
    }
   
    parser.startElementWithPrefix(elementPrefix,
        uri: elementURI,
        localName: elementLocalName,
        attributes: elementAttributes)
}

private func XMLPushSAXParserEndElementSAX(_ ctx: UnsafeMutableRawPointer?,
                                           _ localname: UnsafePointer<xmlChar>?,
                                           _ prefix: UnsafePointer<xmlChar>?,
                                           _ uri: UnsafePointer<xmlChar>?)
{
    let parser = getParser(ctx)
    parser.endElementWithPrefix(getString(prefix),
        uri: getString(uri),
        localName: getString(localname) ?? "")
}

private func XMLPushSAXParserCharactersFoundSAX(_ ctx: UnsafeMutableRawPointer?,
                                                _ ch: UnsafePointer<xmlChar>?,
                                                _ len: Int32)
{
    let parser = getParser(ctx)
    guard let ch = ch else {
        parser.errorOccurred("reported nil characters found")
        return
    }
    
    parser.charactersFound(ch, length: Int(len))
}

// Swift global variables are guaranteed to be lazy initialized in a thread-safe manner!
internal var XMLPushSAXParserHandlerStruct = { () -> xmlSAXHandler in
    var handler = xmlSAXHandler()
    handler.characters = XMLPushSAXParserCharactersFoundSAX
    handler.initialized = XML_SAX2_MAGIC
    handler.startElementNs = XMLPushSAXParserStartElementSAX
    handler.endElementNs = XMLPushSAXParserEndElementSAX
    handler.error = XMLPushSAXParserErrorEncounteredSAX
    return handler
}()

private func getParser(_ ctx: UnsafeMutableRawPointer?) -> LibXMLPushSAXParser {
    guard let ctx = ctx?.assumingMemoryBound(to: LibXMLPushSAXParser.self) else {
        preconditionFailure("ctx ptr must be set")
    }

    return ctx.pointee
}

private func getString(_ pointer: UnsafePointer<xmlChar>?) -> String? {
    guard let pointer = pointer else {
        return nil
    }
    return pointer.withMemoryRebound(to: CChar.self, capacity: 0) { String(cString: $0) }
}
