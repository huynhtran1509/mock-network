//
//  LibXMLPushSAXParser.swift
//
//  Created by Robert Thompson on 8/7/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

import Foundation

public enum PushSaxParserErrorCode: Error {
    case libXML2Error(message: String)
    case usedAfterFinished
}

public struct LibXMLAttribute: Equatable {
    public let localName: String
    public let prefix: String?
    public let URI: String?
    public let value: String
    
    public init(localName: String = "", prefix: String? = nil, URI: String? = nil, value: String = "") {
        self.localName = localName
        self.prefix = prefix
        self.URI = URI
        self.value = value
    }
}

public func ==(lhs: LibXMLAttribute, rhs: LibXMLAttribute) -> Bool {
    return lhs.localName == rhs.localName &&
        lhs.prefix == rhs.prefix &&
        lhs.URI == rhs.URI &&
        lhs.value == rhs.value
}

/// A parser built on libxml2's SAX parsing.
///
/// Calling code must call either: 
/// - `_parse` exactly once, or
/// - `_parseData` any number of times and then `_finishParsing` exactly once.
open class LibXMLPushSAXParser {
    private lazy var __once: () = {
            if self.context != nil {
                xmlFreeParserCtxt(self.context)
                self.unsafeSelf.deinitialize()
                self.context = nil
            }
        }()
    private let unsafeSelf = UnsafeMutablePointer<LibXMLPushSAXParser>.allocate(capacity: 1)
    private var context: xmlParserCtxtPtr? = nil
    private var error: Error?
    
    internal init() {
        unsafeSelf.initialize(to: self)
        self.context = xmlCreatePushParserCtxt(&XMLPushSAXParserHandlerStruct,
            unsafeSelf,
            nil,
            0,
            nil)
    }
    
    internal func _parse(_ data: Data) throws -> Void {
        guard self.context != nil else { throw PushSaxParserErrorCode.usedAfterFinished }
        try _parseData(data)
        try _finishParsing()
    }
    
    internal func _parseData(_ data: Data) throws -> Void {
        guard self.context != nil else { throw PushSaxParserErrorCode.usedAfterFinished }

        _ = data.withUnsafeBytes { (body: UnsafePointer<Int8>) in
            xmlParseChunk(self.context, body, Int32(data.count), 0)
        }
        if let error = self.error {
            throw error
        }
    }
    
    internal func _finishParsing() throws -> Void {
        guard self.context != nil else { throw PushSaxParserErrorCode.usedAfterFinished }

        xmlParseChunk(self.context, nil, 0, 1)
        cleanupContext()
        
        if let error = self.error {
            throw error
        }
    }
    
    open func startElementWithPrefix(_ prefix: String?, uri: String?, localName: String, attributes: [String:LibXMLAttribute]) -> Void { fatalError("Subclass must implement") }
    open func endElementWithPrefix(_ prefix: String?, uri: String?, localName: String) { fatalError("Subclass must implement") }
    open func charactersFound(_ characters: UnsafePointer<xmlChar>, length: Int) { fatalError("Subclass must implement") }
    
    // The following method is dynamic because it gets called from an Objective-C function.
    dynamic func errorOccurred(_ message: String) {
        self.error = PushSaxParserErrorCode.libXML2Error(message: message)
    }

    private var cleanupToken: Int = 0
    private func cleanupContext() {
        _ = self.__once
    }
    
    deinit {
        self.unsafeSelf.deallocate(capacity: 1)
    }
}
