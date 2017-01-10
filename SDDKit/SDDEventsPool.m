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


@implementation SDDELiteralEvent
@synthesize signalName = _signalName;

- (instancetype)initWithSignalName:(NSString *)signalName param:(id)param {
    if (self = [super init]) {
        _signalName = signalName;
        _param = param;
    }
    return self;
}

- (NSString *)description {
    if (self.param) {
        return [NSString stringWithFormat:@"<SDDELiteral %@: %@>", self.signalName, self.param];
    } else {
        return [NSString stringWithFormat:@"<SDDELiteral %@>", self.signalName];
    }
}

@end


#pragma mark -

@interface SDDInternalEventBundle : NSObject
@property (strong, nonatomic) id<SDDEvent> event;
@property (strong, nonatomic) SDDEventCompletion completion;
@end

@implementation SDDInternalEventBundle
@end

SDDInternalEventBundle * SDDMakeInternalEventBundle(id<SDDEvent> event, SDDEventCompletion completion) {
    SDDInternalEventBundle *bundle = [[SDDInternalEventBundle alloc] init];
    bundle.event = event;
    bundle.completion = completion;
    
    return bundle;
}


@implementation SDDEventsPool {
    NSMutableSet        *_subscribers;
    NSMutableArray      *_eventBundles;
    NSMutableArray      *_filters;
    dispatch_semaphore_t _eventSignals;
    
    BOOL _exited;
    dispatch_semaphore_t _ended;
}

- (nonnull instancetype)init {
    if (self = [super init]) {
        _exited       = YES;
        _subscribers  = [NSMutableSet set];
        _filters      = [NSMutableArray array];
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
        BOOL shouldProceed = YES;
        for (id<SDDEventFilter> filter in _filters) {
            if (![filter subscriber:subscriber shouldReceiveEvent:bundle.event]) {
                shouldProceed = NO;
                break; // break filter iterating loop
            }
        }
        
        if (shouldProceed) {
            [subscriber onEvent:bundle.event];
        }
    }
    
    if (bundle.completion != nil) {
        bundle.completion();
    }
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

- (void)addSubscriber:(nonnull id<SDDEventSubscriber>)subscriber {
    @synchronized (_subscribers) {
        [_subscribers addObject:subscriber];
    }
}

- (void)removeSubscriber:(id<SDDEventSubscriber>)subscriber {
    @synchronized (_subscribers) {
        [_subscribers removeObject:subscriber];
    }
}

- (void)scheduleEvent:(nonnull id<SDDEvent>)event withCompletion:(nullable SDDEventCompletion)completion {
    NSAssert(!_exited, @"Events pool should open before scheduling event.");
    
    @synchronized (_eventBundles) {
        [_eventBundles addObject:SDDMakeInternalEventBundle(event, completion)];
    }
    dispatch_semaphore_signal(_eventSignals);
}

- (void)showWarningMessageIfNeeded {
    if ([NSThread isMainThread]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"-[SDDEventsPool scheduleEvent:waitUntilDone:] is calling from main thread with waitUntilDone set to *YES*. It could cause a *DEAD LOCK* if dispatching state actions(activating/deactivating) into main queue. Try using -[SDDEventsPool scheduleEvent:withCompletion:] instead. This message shows only once.");
        });
    }
}

- (void)scheduleEvent:(nonnull id<SDDEvent>)event waitUntilDone:(BOOL)waitUntilDone {
    SDDEventCompletion completion;
    void (^doWaiting)();
    if (waitUntilDone) {
        [self showWarningMessageIfNeeded];
        
        dispatch_semaphore_t doneEvent = dispatch_semaphore_create(0);
        completion = ^{
            dispatch_semaphore_signal(doneEvent);
        };
        doWaiting = ^{
            dispatch_semaphore_wait(doneEvent, DISPATCH_TIME_FOREVER);
        };
    } else {
        completion = nil;
        doWaiting  = ^{};
    }
    
    [self scheduleEvent:event withCompletion:completion];
    doWaiting();
}

- (void)scheduleEvent:(nonnull id<SDDEvent>)event {
    [self scheduleEvent:event waitUntilDone:NO];
}

- (void)addFilter:(id<SDDEventFilter>)filter {
    [_filters addObject:filter];
}

- (void)removeFilter:(id<SDDEventFilter>)filter {
    [_filters removeObject:filter];
}

@end
