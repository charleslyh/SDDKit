//
//  SDDMockFlows.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/5/12.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "SDDMockFlows.h"

@implementation SDDMockFlows {
    NSMutableArray* _flows;
}

- (instancetype)init {
    if (self = [super init]) {
        _flows = [NSMutableArray array];
    }
    return self;
}

- (void)addFlow:(NSString*)flow {
    [_flows addObject:flow];
}

- (NSString *)description {
    return [_flows componentsJoinedByString:@""];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[NSString class]])
        return NO;
    
    return [[self description] isEqualToString:(NSString*)object];
}

@end


@implementation SDDDirectExecutionQueue

- (void)addOperationWithBlock:(void (^)(void))block {
    block();
}

@end