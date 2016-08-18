//
//  LibXMLPushSAXParser.h
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

#import <Foundation/Foundation.h>

// This struct corresponds to the memory layout libxml2 puts in the "attributes" pointer
// for an attribute. Implemented here to ensure future compatibility regardless of changes to the
// Swift ABI. I'm also completely baffled as to why libxml2 doesn't define this struct itself.
typedef struct _LibXMLRawAttribute {
    char* __nullable localName;
    char* __nullable prefix;
    char* __nullable uri;
    char* __nullable valueStart;
    char* __nullable valueEnd;
} LibXMLRawAttribute;

// Swift will only import this as typealias ErrorFunctionPointer = COpaquePointer
typedef void (*LibXMLErrorFunctionPointer)(void * __nullable ctx, const char * __nullable msg, ...);

// This exposes the function pointer to Swift
extern const __nonnull LibXMLErrorFunctionPointer XMLPushSAXParserErrorEncounteredSAX;
