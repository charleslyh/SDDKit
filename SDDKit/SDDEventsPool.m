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

@implementation SDDEventsPool {
    NSMutableSet *_subscribers;
}

- (instancetype)init {
    if (self = [super init]) {
        _subscribers = [NSMutableSet set];
    }
    return self;
}

+ (instancetype)defaultPool {
    static dispatch_once_t onceToken;
    static SDDEventsPool* defaultPool;
    dispatch_once(&onceToken, ^{
        defaultPool = [[SDDEventsPool alloc] init];
    });
    return defaultPool;
}

- (void)addSubscriber:(id<SDDEventSubscriber>)subscriber {
    [_subscribers addObject:subscriber];
}

- (void)removeSubscriber:(id<SDDEventSubscriber>)subscriber {
    [_subscribers removeObject:subscriber];
}

- (void)scheduleEvent:(nonnull SDDEvent*)event {
    [self scheduleEvent:event withParam:nil];
}

- (void)scheduleEvent:(SDDEvent*)event withParam:(id)param {
    for (id<SDDEventSubscriber> subscriber in _subscribers) {
        [subscriber onEvent:event withParam:param];
    }
}

@end
