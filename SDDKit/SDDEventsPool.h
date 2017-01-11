// SDDEventsPool.h
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

@protocol SDDEvent <NSObject>
@property (copy, nonatomic, readonly, nonnull) NSString *signalName;
@end

@interface SDDELiteralEvent : NSObject <SDDEvent>
@property (strong, nonatomic, readonly, nullable) id param;

- (nullable instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithSignalName:(nonnull NSString *)signalName param:(nullable id)param;
@end

/*
 Convience factory macros for making literal events
 Usages:
    void usages(SDDEventsPool *epool) {
        [epool scheduleEvent:SDDELiteral(AnEvent)];
        [epool scheduleEvent:SDDELiteral(EventWithParam, @"StringParam")];
    }
 */
#define SDDELiteral(name)            [[SDDELiteralEvent alloc] initWithSignalName:@#name param:nil]
#define SDDELiteral2(name, paramObj) [[SDDELiteralEvent alloc] initWithSignalName:@#name param:paramObj]


#pragma mark -

@protocol SDDEventSubscriber <NSObject>
- (void)didScheduleEvent:(nonnull id<SDDEvent>)event;
@end

@protocol SDDEventFilter <NSObject>

- (BOOL)subscriber:(nonnull id<SDDEventSubscriber>)subscriber shouldReceiveEvent:(nonnull id<SDDEvent>)event;

@end

#pragma mark -

typedef void (^SDDEventCompletion)();

@interface SDDEventsPool : NSObject

- (nonnull instancetype)init;
+ (nonnull instancetype)sharedPool;

- (void)open;
- (void)close;

- (void)addSubscriber:(nonnull id<SDDEventSubscriber>)subscriber;
- (void)removeSubscriber:(nonnull id<SDDEventSubscriber>)subscriber;

- (void)scheduleEvent:(nonnull id<SDDEvent>)event;
- (void)scheduleEvent:(nonnull id<SDDEvent>)event waitUntilDone:(BOOL)waitUntilDone;
- (void)scheduleEvent:(nonnull id<SDDEvent>)event withCompletion:(nullable SDDEventCompletion)completion;

- (void)addFilter:(nonnull id<SDDEventFilter>)filter;
- (void)removeFilter:(nonnull id<SDDEventFilter>)filter;
@end
