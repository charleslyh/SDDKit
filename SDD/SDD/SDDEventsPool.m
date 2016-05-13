//
//  SDDEventsPool.m
//  SDD
//
//  Created by 黎玉华 on 16/5/5.
//  Copyright © 2016年 yy. All rights reserved.
//

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
