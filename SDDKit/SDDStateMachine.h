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

#import <Foundation/Foundation.h>
#import "SDDEventsPool.h"


typedef BOOL (^SDDCondition)(_Nullable id<SDDEvent> e);
typedef void (^SDDAction)(_Nullable id<SDDEvent> e);
typedef void (^SDDActivation)(_Nullable id<SDDEvent> e);
typedef void (^SDDDeactivation)(_Nullable id<SDDEvent> e);


#pragma mark -


@interface SDDState : NSObject
- (nullable)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithActivation:(nonnull SDDActivation)activation deactivation:(nonnull SDDDeactivation)deactivation;

- (void)activate:(nullable id<SDDEvent>)event;
- (void)deactivate:(nullable id<SDDEvent>)event;
@end

#pragma mark -

@class SDDStateMachine;

@protocol SDDLogger <NSObject>
- (void)didStartStateMachine:(nonnull SDDStateMachine *)stateMachine activates:(nonnull NSArray<SDDState *>*)activatedStates;
- (void)didStopStateMachine:(nonnull SDDStateMachine *)stateMachine deactivates:(nonnull NSArray<SDDState *>*)deactivatedStates;

- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine
           activates:(nonnull NSArray<SDDState *> *)activatedStates
         deactivates:(nonnull NSArray<SDDState *> *)deactivatedStates
             byEvent:(nonnull id<SDDEvent>)event;

@optional
- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine didCallMethodNamed:(nonnull NSString *)name;
@end


typedef NS_OPTIONS(NSInteger, SDDLogMasks) {
    SDDLogMaskStart      = 1 << 0,
    SDDLogMaskStop       = 1 << 1,
    SDDLogMaskTransition = 1 << 2,
    SDDLogMaskCalls      = 1 << 3,
    SDDLogMaskAll        = 0xFFFF,
};

// It is used for console logging

@interface SDDConsoleLogger : NSObject<SDDLogger>
- (nullable)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithMasks:(SDDLogMasks)masks;

+ (nonnull instancetype)defaultLogger;
@end



@interface SDDStateMachine : NSObject <SDDEventSubscriber>
@property (strong, nonatomic, readonly) __nullable id<SDDLogger> logger;

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithLogger:(nullable id<SDDLogger>)logger;

- (void)addState:(nonnull SDDState*)state;
- (void)state:(nonnull SDDState*)state addMonoStates:(nonnull NSArray<SDDState*>*)states;
- (void)setState:(nonnull SDDState *)state defaultState:(nonnull SDDState*)defaultState;
- (void)setTopState:(nonnull SDDState*)state;

- (void)when:(nonnull NSString *)signalName
   satisfied:(nullable SDDCondition)condition
 transitFrom:(nonnull SDDState*)from
          to:(nonnull SDDState*)to
  postAction:(nullable SDDAction)postAction;

- (void)start;
- (void)stop;
@end
