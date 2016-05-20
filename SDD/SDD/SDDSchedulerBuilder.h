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

@interface SDDScheduler (SDDLogSupport)
@property (nonatomic, copy) NSString *sddIdentifier;
@property (nonatomic, copy) NSString *sddDomain;
@property (nonatomic, copy) NSString *sddName;
@property (nonatomic, copy) NSString *sddDSL;
@end

@interface SDDState (SDDLogSupport)
@property (nonatomic, copy) NSString *sddName;
@end


@interface SDDSchedulerBuilder : NSObject
@property (nonatomic, readonly) SDDEventsPool *epool;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithNamespace:(NSString*)namespc
                           logger:(id<SDDSchedulerLogger>)logger
                            queue:(NSOperationQueue*)queue;

- (void)hostSchedulerWithContext:(id)context dsl:(NSString *)dsl;
- (void)hostSchedulerWithContext:(id)context dsl:(NSString *)dsl initialArgument:(id)argument;
@end
