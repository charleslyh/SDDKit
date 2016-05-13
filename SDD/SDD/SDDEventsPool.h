//
//  SDDEventsPool.h
//  SDD
//
//  Created by 黎玉华 on 16/5/5.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString SDDEvent;

@protocol SDDEventSubscriber <NSObject>
- (void)onEvent:(nonnull SDDEvent *)event withParam:(nullable id)param;
@end

@interface SDDEventsPool : NSObject

+ (nonnull instancetype)defaultPool;

- (void)addSubscriber:(nonnull id<SDDEventSubscriber>)subscriber;
- (void)removeSubscriber:(nonnull id<SDDEventSubscriber>)subscriber;

- (void)scheduleEvent:(nonnull SDDEvent*)event;
- (void)scheduleEvent:(nonnull SDDEvent*)event withParam:(nullable id)param;
@end
