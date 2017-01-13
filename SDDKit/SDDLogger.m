//
//  SDDLogger.m
//  SDDKit
//
//  Created by Charles on 2017/1/13.
//  Copyright © 2017年 CharlesLee. All rights reserved.
//

#import "SDDLogger.h"
#import "SDDStateMachine.h"

@implementation SDDConsoleLogger {
    NSString   *_lastMethod;
    SDDLogMasks _masks;
}

+ (instancetype)defaultLogger {
    static SDDConsoleLogger *loggerInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loggerInstance = [[SDDConsoleLogger alloc] initWithMasks:SDDLogMaskAll];
    });
    return loggerInstance;
}

- (nonnull instancetype)initWithMasks:(SDDLogMasks)masks {
    if (self = [super init]) {
        _masks = masks;
    }
    return self;
}

- (NSString *)pathString:(SDDPath *)states {
    NSMutableArray *names = [NSMutableArray array];
    for (SDDState *s in states) {
        [names addObject:[s description]];
    }
    
    return [names componentsJoinedByString:@","];
}

- (void)stateMachine:(SDDStateMachine *)stateMachine didStartWithPath:(SDDPath *)path {
    if (_masks & SDDLogMaskStart) {
        NSLog(@"[SDD][%@(%p)][L] {%@}", stateMachine, stateMachine, [self pathString:path]);
    }
}

- (void)stateMachine:(SDDStateMachine *)stateMachine didStopFromPath:(SDDPath *)path {
    if (_masks & SDDLogMaskStop) {
        NSLog(@"[SDD][%@(%p)][S] {%@}", stateMachine, stateMachine, [self pathString:path]);
    }
}

- (void)stateMachine:(SDDStateMachine *)stateMachine didTransitFromPath:(SDDPath *)from toPath:(SDDPath *)to byEvent:(id<SDDEvent>)event {
    if ((_masks & SDDLogMaskTransition) && (!_stripRepeats || ![from isEqual:to])) {
        NSLog(@"[SDD][%@(%p)][T] %@ | {%@} -> {%@}",
              stateMachine, stateMachine, event, [self pathString:from], [self pathString:to]);
    }
}

- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine didCallMethod:(nonnull NSString *)method {
    if (_masks & SDDLogMaskCalls && (!_stripRepeats || ![method isEqualToString:_lastMethod])) {
        NSLog(@"[SDD][%@(%p)][C] %@", stateMachine, stateMachine, method);
        _lastMethod = [method copy];
    }
}

@end
