//
//  SDDSocketReporter.h
//  SDD
//
//  Created by 黎玉华 on 16/5/17.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDDScheduler.h"
#import "SDDEventsPool.h"

@interface SDDISocketReporter : NSObject<SDDSchedulerLogger, SDDEventSubscriber>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port;

- (void)start;
- (void)stop;

@end

