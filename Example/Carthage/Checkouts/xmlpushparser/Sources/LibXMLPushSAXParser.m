//
//  LibXMLPushSAXParser.m
//
//  Created by Ian Terrell on 7/15/15.
//  Copyright © 2015 WillowTree. All rights reserved.
//

#import "LibXMLPushSAXParser.h"
#import <objc/runtime.h>

void _XMLPushSAXParserErrorEncounteredSAX(void *ctx, const char *msg, ...) {
    va_list args;
    va_start(args, msg);
    char str[1024];
    vsnprintf((char *)str, 1024, (char *)msg, args);
    va_end(args);
    
    // This ugliness is all necessary because Swift does not yet import varidaic C functions
    // Also, the below is even uglier than it would otherwise be, because we're actually passing
    // around a pointer to a pointer to a Swift class. It's not an NSObject. Turns out, though,
    // (and this is official from Apple), Swift class objects do use the Objective-C runtime!
    id __unsafe_unretained* parserPtr = (id __unsafe_unretained*)ctx;
    id parser = *parserPtr;
    SEL errorOccurredSelector = NSSelectorFromString(@"errorOccurred:");
    IMP method = class_getMethodImplementation(NSClassFromString(@"XMLPushParser.LibXMLPushSAXParser"), errorOccurredSelector);
    void (*errorOccurred)(id self, SEL _cmd, NSString* message) = (void (*)(id self, SEL _cmd, NSString* message))method;
    errorOccurred(parser, errorOccurredSelector, [NSString stringWithUTF8String:str]);
}

const LibXMLErrorFunctionPointer XMLPushSAXParserErrorEncounteredSAX = _XMLPushSAXParserErrorEncounteredSAX;
