// SDDScheduler.m
//
// Copyright (c) 2016 CharlesLiyh
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


typedef BOOL (^SDDCondition)(_Nullable id param);
typedef void (^SDDAction)(_Nullable id param);
typedef void (^SDDActivation)(_Nullable id param);
typedef void (^SDDDeactivation)(_Nullable id param);


#pragma mark -

@interface SDDState : NSObject
- (nullable)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithActivation:(nonnull SDDActivation)activation deactivation:(nonnull SDDDeactivation)deactivation;

- (void)activate:(nullable id)argument;
- (void)deactivate:(nullable id)argument;
@end

#pragma mark -

@class SDDScheduler;

@protocol SDDSchedulerLogger <NSObject>
- (void)didStartScheduler:(nonnull SDDScheduler *)scheduler activates:(nonnull NSArray<SDDState *>*)activatedStates;
- (void)didStopScheduler:(nonnull SDDScheduler *)scheduler deactivates:(nonnull NSArray<SDDState *>*)deactivatedStates;

- (void)scheduler:(nonnull SDDScheduler *)scheduler
        activates:(nonnull NSArray<SDDState *>*)activatedStates
      deactivates:(nonnull NSArray<SDDState *>*)deactivatedStates
          byEvent:(nonnull SDDEvent *)event;

@optional
- (void)didLaunchContextMethodWithName:(nonnull NSString *)methodName;
@end


typedef NS_OPTIONS(NSInteger, SDDSchedulerLogMasks) {
    SDDSchedulerLogMaskStart      = 1 << 0,
    SDDSchedulerLogMaskStop       = 1 << 1,
    SDDSchedulerLogMaskTransition = 1 << 2,
    SDDSchedulerLogMaskAll        = 0xFFFF,
};

// It is used for console logging

@interface SDDSchedulerConsoleLogger : NSObject<SDDSchedulerLogger>
- (nullable)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithMasks:(SDDSchedulerLogMasks)masks;
@end



@interface SDDScheduler : NSObject
@property (strong, nonatomic, readonly) __nullable id<SDDSchedulerLogger> logger;

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithOperationQueue:(nonnull NSOperationQueue*)queue logger:(nullable id<SDDSchedulerLogger>)logger;

- (void)addState:(nonnull SDDState*)state;
- (void)state:(nonnull SDDState*)state addMonoStates:(nonnull NSArray<SDDState*>*)states;
- (void)setState:(nonnull SDDState *)state defaultState:(nonnull SDDState*)defaultState;
- (void)setRootState:(nonnull SDDState*)state;

- (void)when:(nonnull SDDEvent*)event
   satisfied:(nullable SDDCondition)condition
 transitFrom:(nonnull SDDState*)from
          to:(nonnull SDDState*)to
  postAction:(nullable SDDAction)postAction;

- (void)startWithEventsPool:(nonnull SDDEventsPool*)epool;
- (void)startWithEventsPool:(nonnull SDDEventsPool*)epool initialArgument:(nullable id)argument;
- (void)stop;
@end
