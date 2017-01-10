// SDDSchedulerBuilder.m
//
// Copyright (c) 2016 CharlesLiyh
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/message.h>
#import <objc/runtime.h>
#import "SDDSchedulerBuilder.h"
#import "SDDScheduler.h"
#import "sdd_parser.h"
#import "sdd_array.h"

static const void* kSDDStateBuilderNameKey       = &kSDDStateBuilderNameKey;
static const void* kSDDStateBuilderDSLKey        = &kSDDStateBuilderDSLKey;
static const void* kSDDStateBuilderIdentifierKey = &kSDDStateBuilderIdentifierKey;
static const void* kSDDStateBuilderDomainKey     = &kSDDStateBuilderDomainKey;

@interface SDDScheduler(SDDProperties)
@property (copy, nonatomic) NSString *sddName;
@property (copy, nonatomic) NSString *sddDSL;
@property (copy, nonatomic) NSString *sddIdentifier;
@property (copy, nonatomic) NSString *sddDomain;
@end

@implementation SDDScheduler(SDDProperties)

@end

@implementation SDDScheduler (SDDLogSupport)

- (void)setSddDSL:(NSString *)sddDSL {
    objc_setAssociatedObject(self, kSDDStateBuilderDSLKey, sddDSL, OBJC_ASSOCIATION_COPY);
}

- (NSString *)sddDSL {
    return objc_getAssociatedObject(self, kSDDStateBuilderDSLKey);
}

- (void)setSddName:(NSString *)sddName {
    objc_setAssociatedObject(self, kSDDStateBuilderNameKey, sddName, OBJC_ASSOCIATION_COPY);
}

- (NSString *)sddName {
    return objc_getAssociatedObject(self, kSDDStateBuilderNameKey);
}

- (void)setSddIdentifier:(NSString *)sddIdentifier {
    objc_setAssociatedObject(self, kSDDStateBuilderIdentifierKey, sddIdentifier, OBJC_ASSOCIATION_COPY);
}

- (NSString *)sddIdentifier {
    return objc_getAssociatedObject(self, kSDDStateBuilderIdentifierKey);
}

- (void)setSddDomain:(NSString *)sddDomain {
    objc_setAssociatedObject(self, kSDDStateBuilderDomainKey, sddDomain, OBJC_ASSOCIATION_COPY);
}

- (NSString *)sddDomain {
    return objc_getAssociatedObject(self, kSDDStateBuilderDomainKey);
}

- (NSString*)description {
    NSString *name = [self sddName];
    if (name == nil)
        return [super description];
    
    return name;
}

@end


#pragma mark -

static const void* kSDDStateNameKey       = &kSDDStateNameKey;

@interface SDDState (SDDProperties)
@property (copy, nonatomic) NSString *sddName;
@end

@implementation SDDState (SDDProperties)

- (void)setSddName:(NSString *)sddName {
    objc_setAssociatedObject(self, kSDDStateNameKey, sddName, OBJC_ASSOCIATION_COPY);
}

- (NSString *)sddName {
    return objc_getAssociatedObject(self, kSDDStateNameKey);
}

@end

@implementation SDDState (SDDLogSupport)
@dynamic sddName;

- (NSString*)description {
    NSString *name = [self sddName];
    if (name == nil)
        return [super description];
    
    return name;
}

@end


@implementation NSString (SDDSplitActions)

- (NSArray*)sddNamedComponents {
    NSArray* acts = [self componentsSeparatedByString:@" "];
    if (acts.count == 1 && [acts[0] length] == 0) {
        return @[];
    }
    
    return acts;
}

@end



@interface SDDParserContext : NSObject 
@property (nonatomic, weak) id runtimeContext;
@property (nonatomic, weak) SDDScheduler* scheduler;
@property (nonatomic, weak) NSMutableDictionary<NSString*, SDDState*>* states;
@end

@implementation SDDParserContext

- (SDDState*)stateWithCName:(const char*)cname {
    NSString* name = [NSString stringWithCString:cname encoding:NSUTF8StringEncoding];
    return self.states[name];
}

- (SDDState*)stateWithRawState:(sdd_state*)raw_state {
    return [self stateWithCName:raw_state->name];
}

@end

typedef BOOL (*SDDConditionMsgSendtionImp)(id, SEL);
typedef BOOL (*SDDConditionMsgSendtionImp2)(id, SEL, id);
static SDDConditionMsgSendtionImp SDDConditionMsgSend   = (SDDConditionMsgSendtionImp)objc_msgSend;
static SDDConditionMsgSendtionImp2 SDDConditionMsgSend2 = (SDDConditionMsgSendtionImp2)objc_msgSend;

typedef void (*SDDSimpleActionImp)(id, SEL);
typedef void (*SDDAugmentedActionImp)(id, SEL, id);
static SDDSimpleActionImp SDDSimpleAction       = (SDDSimpleActionImp)objc_msgSend;
static SDDAugmentedActionImp SDDAugmentedAction = (SDDAugmentedActionImp)objc_msgSend;

void SDDSchedulerAddState(void* contextObj, sdd_state* raw_state) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    __weak SDDScheduler* scheduler = pcontext.scheduler;
    __weak id context = pcontext.runtimeContext;
    
    NSString* entries = [NSString stringWithCString:raw_state->entries encoding:NSUTF8StringEncoding];
    NSString* exits   = [NSString stringWithCString:raw_state->exits   encoding:NSUTF8StringEncoding];
    
    SDDActivation activation = ^(id argument) {
        NSArray* acts = [entries sddNamedComponents];
        for (NSString* act in acts) {
            SEL simpleSel    = NSSelectorFromString(act);
            SEL augmentedSel = NSSelectorFromString([NSString stringWithFormat:@"%@:", act]);
            
            if ([context respondsToSelector:simpleSel]) {
                SDDSimpleAction(context, simpleSel);
            } else if ([context respondsToSelector:augmentedSel]) {
                SDDAugmentedAction(context, augmentedSel, argument);
            } else if (context != nil) {
                [[NSException exceptionWithName:@"SDDSchedulerBuilderException"
                                         reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, act]
                                       userInfo:@{
                                                  @"context": context ? context : @"null",
                                                  @"action":  act,
                                                  }] raise];
            }

            if ([scheduler.logger respondsToSelector:@selector(scheduler:didCallMethodNamed:)]) {
                [scheduler.logger scheduler:scheduler didCallMethodNamed:act];
            }
        }
    };

    SDDDeactivation deactivation = ^(id argument) {
        NSArray* acts = [exits sddNamedComponents];
        for (NSString* act in acts) {
            SEL simpleSel    = NSSelectorFromString(act);
            SEL augmentedSel = NSSelectorFromString([NSString stringWithFormat:@"%@:", act]);

            if ([context respondsToSelector:simpleSel]) {
                SDDSimpleAction(context, simpleSel);
            } else if ([context respondsToSelector:augmentedSel]) {
                SDDAugmentedAction(context, augmentedSel, argument);
            } else if (context != nil) {
                [[NSException exceptionWithName:@"SDDSchedulerBuilderException"
                                         reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, act]
                                       userInfo:@{
                                                  @"context": context ? context : @"null",
                                                  @"action":  act,
                                                  }] raise];
            }

            if ([scheduler.logger respondsToSelector:@selector(scheduler:didCallMethodNamed:)]) {
                [scheduler.logger scheduler:scheduler didCallMethodNamed:act];
            }
        }
    };

    NSString* name = [NSString stringWithCString:raw_state->name encoding:NSUTF8StringEncoding];
    SDDState* state = [[SDDState alloc] initWithActivation:activation deactivation:deactivation];
    state.sddName = name;
    pcontext.states[name] = state;
    [pcontext.scheduler addState:state];
    [pcontext.scheduler setState:state defaultState:[pcontext stateWithCName:raw_state->default_stub]];
}

void SDDSchedulerSetDescendants(void* contextObj, sdd_state* raw_master, sdd_array* raw_descendants) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    
    NSMutableArray* descendants = [NSMutableArray array];
    for (int i=0; i<sdd_array_count(raw_descendants); ++i) {
        sdd_state* raw_state = sdd_array_at(raw_descendants, i, YES);
        [descendants addObject:[pcontext stateWithRawState:raw_state]];
    }
    
    SDDState* master = [pcontext stateWithRawState:raw_master];
    [pcontext.scheduler state:master addMonoStates:descendants];
}

void SDDSchedulerMakeTransition(void* contextObj, sdd_transition* t) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    __weak SDDScheduler* scheduler = pcontext.scheduler;
    __weak id context = pcontext.runtimeContext;
    
    NSString* names = [NSString stringWithCString:t->actions encoding:NSUTF8StringEncoding];
    SDDAction postAction = ^(id argument) {
        NSArray* acts = [names sddNamedComponents];
        for (NSString* act in acts) {
            SEL simpleSel    = NSSelectorFromString(act);
            SEL augmentedSel = NSSelectorFromString([NSString stringWithFormat:@"%@:", act]);
            
            if ([context respondsToSelector:simpleSel]) {
                SDDSimpleAction(context, simpleSel);
            } else if ([context respondsToSelector:augmentedSel]) {
                SDDAugmentedAction(context, augmentedSel, argument);
            } else if (context != nil) {
                [[NSException exceptionWithName:@"SDDSchedulerBuilderException"
                                         reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, act]
                                       userInfo:@{
                                                  @"context": context ? context : @"null",
                                                  @"action":  act,
                                                  }] raise];
            }

            if ([scheduler.logger respondsToSelector:@selector(scheduler:didCallMethodNamed:)]) {
                [scheduler.logger scheduler:scheduler didCallMethodNamed:act];
            }
        }
    };
    
    NSString* conditions = [NSString stringWithCString:t->conditions encoding:NSUTF8StringEncoding];
    SDDCondition condition = ^BOOL (id argument) {
        NSArray* components = [conditions sddNamedComponents];
        if (components.count == 0)
            return YES;
        
        NSMutableArray* evalStack = [NSMutableArray array];
        for (NSString* p in components) {
            BOOL exprValue = YES;
            if ([p isEqualToString:@"!"]) {
                BOOL value = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                exprValue = !value;
            } else if ([p isEqualToString:@"|"]) {
                BOOL rightValue = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                BOOL leftValue  = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                exprValue = leftValue || rightValue;
            } else if ([p isEqualToString:@"&"]) {
                BOOL rightValue = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                BOOL leftValue  = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                exprValue = leftValue && rightValue;
            } else if ([p isEqualToString:@"^"]) {
                BOOL rightValue = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                BOOL leftValue  = [[evalStack lastObject] boolValue]; [evalStack removeLastObject];
                exprValue = leftValue ^ rightValue;
            } else {
                SEL simpleSel    = NSSelectorFromString(p);
                SEL augmentedSel = NSSelectorFromString([NSString stringWithFormat:@"%@:", p]);
                if ([context respondsToSelector:simpleSel]) {
                    exprValue = SDDConditionMsgSend(context, simpleSel);
                } else if ([context respondsToSelector:augmentedSel]) {
                    exprValue = SDDConditionMsgSend2(context, augmentedSel, argument);
                } else if (context != nil) {
                    [[NSException exceptionWithName:@"SDDSchedulerBuilderException"
                                             reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, p]
                                           userInfo:@{
                                                      @"context":   context ? context : @"null",
                                                      @"condition": p,
                                                      }] raise];
                }
            }
            
            [evalStack addObject:@(exprValue)];
        }
        
        return [[evalStack lastObject] boolValue];
    };

    SDDState* fromState = [pcontext stateWithCName:t->from];
    SDDState* toState   = [pcontext stateWithCName:t->to];
    NSString* eventID   = [NSString stringWithCString:t->event encoding:NSUTF8StringEncoding];
    [pcontext.scheduler when:eventID satisfied:condition transitFrom:fromState to:toState postAction:postAction];
}

void SDDSchedulerBuilderHandleCompletion(void *contextObj, sdd_state *root_state) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    
    SDDState *rootState = [pcontext stateWithCName:root_state->name];
    [pcontext.scheduler setRootState:rootState];
    pcontext.scheduler.sddName = [NSString stringWithUTF8String:root_state->name];
}

@implementation SDDSchedulerBuilder {
    id<SDDSchedulerLogger> _logger;
    NSOperationQueue       *_queue;
    SDDEventsPool          *_epool;
    
    NSMutableArray         *_schedulers;
}

- (instancetype)initWithLogger:(id<SDDSchedulerLogger>)logger epool:(SDDEventsPool *)epool {
    if (self = [super init]) {
        _logger     = logger;
        _epool      = epool;
        _schedulers = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    for (SDDScheduler *s in _schedulers) {
        [s stop];
    }
}

- (SDDScheduler*)schedulerWithContext:(id)context dsl:(NSString*)dsl {
    SDDScheduler* scheduler = [[SDDScheduler alloc] initWithLogger:_logger];
    scheduler.sddDSL = dsl;
    
    NSMutableDictionary* states = [NSMutableDictionary dictionary];
    
    SDDParserContext* pcontext = [[SDDParserContext alloc] init];
    pcontext.states = states;
    pcontext.runtimeContext = context;
    pcontext.scheduler = scheduler;
    
    sdd_parser_callback callback;
    callback.context = (__bridge void*)pcontext;
    callback.stateHandler      = &SDDSchedulerAddState;
    callback.clusterHandler    = &SDDSchedulerSetDescendants;
    callback.transitionHandler = &SDDSchedulerMakeTransition;
    callback.completionHandler = &SDDSchedulerBuilderHandleCompletion;
    
    sdd_parse([dsl cStringUsingEncoding:NSUTF8StringEncoding], &callback);
    return scheduler;
}

- (SDDScheduler *)addSchedulerWithContext:(id)context dsl:(NSString *)dsl {
    SDDScheduler *scheduler = [self schedulerWithContext:context dsl:dsl];
    scheduler.sddIdentifier = SDDMakeUUID();
    
    [scheduler startWithEventsPool:_epool];
    [_schedulers addObject:scheduler];
    return scheduler;
}

- (void)removeScheduler:(SDDScheduler *)scheduler {
    [scheduler stop];
    [_schedulers removeObject:scheduler];
}

NSString * SDDMakeUUID() {
    CFUUIDRef uuidObj = CFUUIDCreate(nil);//create a new UUID
    NSString  *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    
    return uuidString ;
}

@end
