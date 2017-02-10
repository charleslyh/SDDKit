//
//  SDDLogger.h
//  SDDKit
//
//  Created by Charles on 2017/1/13.
//  Copyright © 2017年 CharlesLee. All rights reserved.
//

#import "SDDStateMachine.h"
#import <Foundation/Foundation.h>

@protocol SDDLogger <NSObject>
- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine didStartWithPath:(nonnull SDDPath*)path;
- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine didStopFromPath:(nonnull SDDPath*)path;

- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine
  didTransitFromPath:(nonnull SDDPath *)fromPath
              toPath:(nonnull SDDPath *)toPath
             byEvent:(nonnull id<SDDEvent>)event;

@optional
- (void)stateMachine:(nonnull SDDStateMachine *)stateMachine didCallMethod:(nonnull NSString *)method;
@end

#pragma - SDDConsoleLogger

typedef NS_OPTIONS(NSInteger, SDDLogMasks) {
    SDDLogMaskStart      = 1 << 0,
    SDDLogMaskStop       = 1 << 1,
    SDDLogMaskTransition = 1 << 2,
    SDDLogMaskCalls      = 1 << 3,
    SDDLogMaskAll        = 0xFFFF,
};

// It is used for console logging

@interface SDDConsoleLogger : NSObject <SDDLogger>
@property (assign, nonatomic) BOOL groupRepeatCalls;
@property (assign, nonatomic) BOOL stripSelfTransitions;

- (nullable)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithMasks:(SDDLogMasks)masks;
+ (nonnull instancetype)defaultLogger;

- (void)setAlias:(nonnull NSString *)alias forHSM:(nonnull SDDStateMachine *)hsm;
@end

