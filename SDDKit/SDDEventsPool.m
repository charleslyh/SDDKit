// SDDEventsPool.m
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


@implementation SDDELiteralEvent
@synthesize signalName = _signalName;

- (instancetype)initWithSignalName:(NSString *)signalName param:(id)param {
    if (self = [super init]) {
        _signalName = signalName;
        _param      = param;
    }
    return self;
}

// description will make logs looking better.
- (NSString *)description {
    if (self.param) {
        return [NSString stringWithFormat:@"<%@: %@>", self.signalName, self.param];
    } else {
        return [NSString stringWithFormat:@"<%@>", self.signalName];
    }
}

@end


#pragma mark -

@implementation SDDEventsPool {
    NSRecursiveLock     *_processingLock;
    NSMutableSet        *_subscribers;
    NSMutableArray      *_events;
    NSMutableArray      *_filters;
}

- (nonnull instancetype)init {
    if (self = [super init]) {
        _processingLock = [[NSRecursiveLock alloc] init];
        _subscribers  = [NSMutableSet set];
        _filters      = [NSMutableArray array];
        _events       = [NSMutableArray array];
    }
    return self;
}

- (void)dispatchTopEvent {
    id<SDDEvent> event = _events.lastObject;
    
    // Subscribers could be inserted or removed while event dispatching (in the loop)
    NSArray *subscribersCopy;
    @synchronized (_subscribers) {
        subscribersCopy = [_subscribers copy];
    }
    
    for (id<SDDEventSubscriber> subscriber in subscribersCopy) {
        BOOL shouldProceed = YES;
        for (id<SDDEventFilter> filter in _filters) {
            if (![filter subscriber:subscriber shouldReceiveEvent:event]) {
                shouldProceed = NO;
                break; // break filter iterating loop
            }
        }
        
        if (shouldProceed) {
            [subscriber didScheduleEvent:event];
        }
    }
    
    [_events removeObjectAtIndex:0];
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

- (void)scheduleEvent:(nonnull id<SDDEvent>)event {
    [_processingLock lock];
    
    BOOL isProcessing = _events.count >= 1;
    
    [_events addObject:event];
    
    if (!isProcessing) {
        while(_events.count > 0) {
            [self dispatchTopEvent];
        }
    }

    [_processingLock unlock];
}

- (void)addFilter:(id<SDDEventFilter>)filter {
    [_filters addObject:filter];
}

- (void)removeFilter:(id<SDDEventFilter>)filter {
    [_filters removeObject:filter];
}

@end
