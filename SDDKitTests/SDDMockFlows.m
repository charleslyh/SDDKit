//
//  SDDMockFlows.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/5/12.
//  Copyright © 2016年 CharlesLee All rights reserved.
//

#import "SDDMockFlows.h"

@implementation SDDMockFlows {
    NSMutableArray* _items;
}

- (instancetype)init {
    if (self = [super init]) {
        _items = [NSMutableArray array];
    }
    return self;
}

- (NSString *)stringValue {
    return [_items componentsJoinedByString:@""];
}

- (void)markItem:(NSString*)item {
    [_items addObject:item];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[NSString class]])
        return NO;
    
    return [[self stringValue] isEqualToString:(NSString*)object];
}

- (NSString *)description {
    return [self stringValue];
}

@end
