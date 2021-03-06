// SDDBuilder.h
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

#import "SDDStateMachine.h"
#import <Foundation/Foundation.h>

#define SDDOCLanguage(dsl) @#dsl

@class SDDEventsPool, SDDStateMachine;
@protocol SDDEvent, SDDLogger;

@interface SDDBuilder : NSObject
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithLogger:(id<SDDLogger>)logger epool:(SDDEventsPool *)epool;

- (SDDStateMachine *)addStateMachineWithContext:(id)context dsl:(NSString *)dsl;
- (void)removeStateMachine:(SDDStateMachine *)stateMachine;

- (void)hookAction:(NSString *)action withBlock:(SDDAction)block;
- (void)hookCondition:(NSString *)condition withBlock:(SDDCondition)block;

@end
