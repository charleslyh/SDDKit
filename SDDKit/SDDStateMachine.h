// SDDStateMachine.m
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

#import "SDDEventsPool.h"
#import <Foundation/Foundation.h>


typedef BOOL (^SDDCondition)(_Nullable id<SDDEvent> e);
typedef void (^SDDAction)(_Nullable id<SDDEvent> e);
typedef SDDAction SDDActivation;
typedef SDDAction SDDDeactivation;

@interface SDDState : NSObject
- (nullable)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithActivation:(nonnull SDDActivation)activation deactivation:(nonnull SDDDeactivation)deactivation;

- (void)activate:(nullable id<SDDEvent>)event;
- (void)deactivate:(nullable id<SDDEvent>)event;
@end

typedef NSArray<SDDState *> SDDPath;

#pragma mark -

@protocol SDDLogger;
@class SDDStateMachine;

@interface SDDStateMachine : NSObject <SDDEventSubscriber>
@property (strong, nonatomic, readonly) SDDState *    __nonnull  outterState;
@property (strong, nonatomic, readonly) SDDState *    __nonnull  topState;

@property (strong, nonatomic, readonly) id<SDDLogger> __nullable logger;

- (nullable instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithLogger:(nullable id<SDDLogger>)logger;

- (void)addState:(nonnull SDDState*)state;
- (void)setParentState:(nonnull SDDState *)parent forChildState:(nonnull SDDState *)child;
- (void)setTopState:(nonnull SDDState*)state;

- (void)when:(nonnull NSString *)signalName
   satisfied:(nullable SDDCondition)condition
 transitFrom:(nonnull SDDState*)from
          to:(nonnull SDDState*)to
  postAction:(nullable SDDAction)postAction;

- (void)start;
- (void)stop;
@end
