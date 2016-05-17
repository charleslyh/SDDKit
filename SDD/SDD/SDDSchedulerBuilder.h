//
//  SDDMachineBuilder.h
//  YYMSAuth
//
//  Created by 黎玉华 on 16/1/22.
//  Copyright © 2016年 YY.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDDScheduler.h"


#define SDDOCLanguage(dsl) [NSString stringWithFormat:@"%s", #dsl]


@class SDDEventsPool;
@protocol SDDSchedulerLogger;

@interface SDDScheduler (SDDNameSupport)
- (void)sdd_setName:(NSString *)name;
- (NSString *)sdd_name;

- (void)sdd_setDSL:(NSString *)dsl;
- (NSString *)sdd_DSL;
@end

@interface SDDState (SDDNameSupport)
- (void)sdd_setName:(NSString*)name;
- (NSString*)sdd_name;
@end


@interface SDDSchedulerBuilder : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithNamespace:(NSString*)namespc logger:(id<SDDSchedulerLogger>)logger;

- (SDDScheduler*)schedulerWithContext:(id)context dsl:(NSString*)dsl queue:(NSOperationQueue*)queue;
@end
