//
//  SDDState.h
//  SDD
//
//  Created by 黎玉华 on 16/3/25.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDDEventsPool.h"


typedef BOOL (^SDDCondition)(_Nullable id param);
typedef void (^SDDAction)(_Nullable id param);
typedef void (^SDDActivation)(_Nullable id param);
typedef void (^SDDDeactivation)();


#pragma mark -

@interface SDDState : NSObject
- (nonnull instancetype)initWithActivation:(nonnull SDDActivation)activation deactivation:(nonnull SDDDeactivation)deactivation;
- (void)activate:(nullable id)argument;
- (void)deactivate;
@end

#pragma mark -

@interface SDDScheduler : NSObject
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
- (nonnull instancetype)initWithOperationQueue:(nonnull NSOperationQueue*)queue;

- (void)addState:(nonnull SDDState*)state;
- (void)state:(nonnull SDDState*)state addMonoStates:(nonnull NSArray<SDDState*>*)states;
- (void)setState:(nonnull SDDState *)state defaultState:(nonnull SDDState*)defaultState;
- (void)setRootState:(nonnull SDDState*)state;

- (void)when:(nonnull SDDEvent*)event
   satisfied:(nullable SDDCondition)condition
 transitFrom:(nonnull SDDState*)from
          to:(nonnull SDDState*)to
  postAction:(nullable SDDAction)postAction;

- (void)startWithEventsPool:(nonnull SDDEventsPool*)epool;
- (void)startWithEventsPool:(nonnull SDDEventsPool*)epool initialArgument:(nullable id)argument;
- (void)stop;
@end