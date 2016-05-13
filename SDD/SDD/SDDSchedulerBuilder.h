//
//  SDDMachineBuilder.h
//  YYMSAuth
//
//  Created by 黎玉华 on 16/1/22.
//  Copyright © 2016年 YY.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SDDOCLanguage(dsl) [NSString stringWithFormat:@"%s", #dsl]

@class SDDScheduler, SDDState, SDDEventsPool;

@interface SDDSchedulerBuilder : NSObject
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithNamespace:(NSString*)namespc;

- (SDDScheduler*)schedulerWithContext:(id)context eventsPool:(SDDEventsPool*)epool dsl:(NSString*)dsl queue:(NSOperationQueue*)queue;
@end
