//
//  SDDLogger.m
//  SDDKit
//
// Copyright (c) 2016 CharlesLee
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SDDLogger.h"
#import "SDDStateMachine.h"

@implementation SDDConsoleLogger {
    NSString   *_lastMethod;
    SDDLogMasks _masks;
}

+ (instancetype)defaultLogger {
    static SDDConsoleLogger *loggerInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Method calling is stripped by default
        loggerInstance = [[SDDConsoleLogger alloc] initWithMasks:(SDDLogMaskAll & ~SDDLogMaskCalls)];
    });
    return loggerInstance;
}

- (nonnull instancetype)initWithMasks:(SDDLogMasks)masks {
    if (self = [super init]) {
        _masks = masks;
    }
    return self;
}

- (NSString *)pathString:(SDDPath *)states {
    NSMutableArray *names = [NSMutableArray array];
    for (SDDState *s in states) {
        [names addObject:[s description]];
    }
    
    return [names componentsJoinedByString:@","];
}

void SDDLog(SDDStateMachine *hsm, char typeChar, NSString *format, ...) {
    NSString *prefixString = [NSString stringWithFormat:@"[SDD][%@(%p)][%c]", hsm, hsm, typeChar];

    va_list arg_ptr;
    va_start(arg_ptr, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arg_ptr];
    va_end(arg_ptr);

    NSLog(@"%@ %@", prefixString, message);
}

- (void)stateMachine:(SDDStateMachine *)hsm didStartWithPath:(SDDPath *)path {
    if (_masks & SDDLogMaskStart) {
        SDDLog(hsm, 'L', @"{%@}", [self pathString:path]);
    }
}

- (void)stateMachine:(SDDStateMachine *)hsm didStopFromPath:(SDDPath *)path {
    if (_masks & SDDLogMaskStop) {
        SDDLog(hsm, 'S', @"{%@}", [self pathString:path]);
    }
}

- (void)stateMachine:(SDDStateMachine *)hsm didTransitFromPath:(SDDPath *)from toPath:(SDDPath *)to byEvent:(id<SDDEvent>)event {
    if ((_masks & SDDLogMaskTransition) && (!_stripRepeats || ![from isEqual:to])) {
        SDDLog(hsm, 'T', @"%@ | {%@} -> {%@}", event, [self pathString:from], [self pathString:to]);
    }
}

- (void)stateMachine:(nonnull SDDStateMachine *)hsm didCallMethod:(nonnull NSString *)method {
    if (_masks & SDDLogMaskCalls && (!_stripRepeats || ![method isEqualToString:_lastMethod])) {
        SDDLog(hsm, 'C', @"%@", method);
        _lastMethod = [method copy];
    }
}

@end
