//
//  SDDDirectExecutionQueue.m
//  SDDKit
//
//  Created by Charles on 2017/1/8.
//  Copyright © 2017年 Capsule. All rights reserved.
//

#import "SDDDirectExecutionQueue.h"

@implementation SDDDirectExecutionQueue

- (void)addOperationWithBlock:(void (^)(void))block {
    block();
}

@end

