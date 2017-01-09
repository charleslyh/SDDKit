// SDDEventsPool.m
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

#import "SDDEventsPool.h"

@interface SDDInternalEventBundle : NSObject
@property (strong, nonatomic) SDDEvent *event;
@property (strong, nonatomic) id param;
@property (strong, nonatomic) SDDEventCompletion completion;
@end

@implementation SDDInternalEventBundle
@end

SDDInternalEventBundle * SDDMakeInternalEventBundle(SDDEvent *event, id param, SDDEventCompletion completion) {
    SDDInternalEventBundle *bundle = [[SDDInternalEventBundle alloc] init];
    bundle.event = event;
    bundle.param = param;
    bundle.completion = completion;
    
    return bundle;
}


@implementation SDDEventsPool {
    NSMutableSet        *_subscribers;
    dispatch_semaphore_t _eventSignals;
    NSMutableArray      *_eventBundles;
    
    BOOL _exited;
    dispatch_semaphore_t _ended;
}

- (nonnull instancetype)init {
    if (self = [super init]) {
        _exited       = YES;
        _subscribers  = [NSMutableSet set];
        _eventBundles = [NSMutableArray array];
        _eventSignals = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)dealloc {
    NSAssert(_exited, @"Could not dealloc a running SDDEventsPool object");
}

- (void)open {
    NSAssert(_exited, @"Events Pool already open.");
    
    _exited = NO;
    dispatch_queue_t loopQueue = dispatch_queue_create(nil, nil);
    _ended = dispatch_semaphore_create(0);
    dispatch_async(loopQueue, ^{
        [self dispatchingLoop];
    });
}

- (void)close {
    NSAssert(!_exited, @"Events pool not open yet.");
    
    if (_eventBundles.count > 0) {
        NSLog(@"It is strongly recommend that you handle all events.");
    }
    
    _exited = YES;
    dispatch_semaphore_signal(_eventSignals);
    dispatch_semaphore_wait(_ended, DISPATCH_TIME_FOREVER);
}

- (void)dispatchTopEvent {
    // Event scheduling could happen while dispatching, thus, _events have to be locked.
    SDDInternalEventBundle *bundle;
    @synchronized (_eventBundles) {
        bundle = _eventBundles.firstObject;
        NSAssert(bundle!=nil, @"There is a signal, then there should be an event.");
        [_eventBundles removeObjectAtIndex:0];
    }
    
    // Subscribers could be inserted or removed while event dispatching (in the loop)
    NSArray *subscribersCopy;
    @synchronized (_subscribers) {
        subscribersCopy = [_subscribers copy];
    }
    
    for (id<SDDEventSubscriber> subscriber in subscribersCopy) {
        [subscriber onEvent:bundle.event withParam:bundle.param];
    }
    
    if (bundle.completion != nil) {
        bundle.completion();
    }
    
    NSLog(@"[SDD] done event: %@", bundle.event);
}

- (void)dispatchingLoop {
    while (!_exited) {
        dispatch_semaphore_wait(_eventSignals, DISPATCH_TIME_FOREVER);
        if (_exited) {
            break;
        }
 
        [self dispatchTopEvent];
    }
    
    dispatch_semaphore_signal(_ended);
}

+ (instancetype)sharedPool {
    static dispatch_once_t onceToken;
    static SDDEventsPool* defaultPool;
    dispatch_once(&onceToken, ^{
        defaultPool = [[SDDEventsPool alloc] init];
    });
    return defaultPool;
}

- (void)addSubscriber:(id<SDDEventSubscriber>)subscriber {
    @synchronized (_subscribers) {
        [_subscribers addObject:subscriber];
    }
}

- (void)removeSubscriber:(id<SDDEventSubscriber>)subscriber {
    @synchronized (_subscribers) {
        [_subscribers removeObject:subscriber];
    }
}

- (void)scheduleEvent:(nonnull SDDEvent*)event {
    [self scheduleEvent:event withParam:nil completion:nil];
}

- (void)scheduleEvent:(nonnull SDDEvent*)event withParam:(nullable id)param {
    [self scheduleEvent:event withParam:param completion:nil];
}

- (void)scheduleEvent:(nonnull SDDEvent*)event withCompletion:(nullable SDDEventCompletion)completion {
    [self scheduleEvent:event withParam:nil completion:completion];
}

- (void)scheduleEvent:(SDDEvent*)event withParam:(id)param completion:(nullable SDDEventCompletion)completion {
    NSAssert(!_exited, @"Events pool should open before scheduling event.");

    @synchronized (_eventBundles) {
        [_eventBundles addObject:SDDMakeInternalEventBundle(event, param, completion)];
    }
    
    dispatch_semaphore_signal(_eventSignals);
    
    NSLog(@"[SDD] scheduled event: %@", event);
}

@end
