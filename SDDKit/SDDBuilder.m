// SDDBuilder.m
//
// Copyright (c) 2016 CharlesLee
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

#import "SDDBuilder.h"
#import "SDDLogger.h"
#import "SDDStateMachine.h"
#import "sdd_parser.h"
#import "sdd_array.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface SDDStateMachine (SDDLogSupport)
@property (nonatomic, copy) NSString *sddName;
@end

@interface SDDState (SDDLogSupport)
@property (nonatomic, copy) NSString *sddName;
@end


static const void* kSDDStateBuilderNameKey       = &kSDDStateBuilderNameKey;

@interface SDDStateMachine(SDDProperties)
@property (copy, nonatomic) NSString *sddName;
@end

@implementation SDDStateMachine (SDDLogSupport)

- (void)setSddName:(NSString *)sddName {
    objc_setAssociatedObject(self, kSDDStateBuilderNameKey, sddName, OBJC_ASSOCIATION_COPY);
}

- (NSString *)sddName {
    return objc_getAssociatedObject(self, kSDDStateBuilderNameKey);
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
@property (nonatomic, weak) NSDictionary    *actionBlocks;
@property (nonatomic, weak) NSDictionary    *conditionBlocks;
@property (nonatomic, weak) SDDStateMachine *stateMachine;
@property (nonatomic, weak) NSMutableDictionary<NSString*, SDDState*>* states;
@end

@implementation SDDParserContext

- (SDDState*)stateWithCName:(const char*)cname {
    if (strcmp(cname, ".") == 0) {
        return self.stateMachine.outterState;
    } else {
        NSString* name = [NSString stringWithCString:cname encoding:NSUTF8StringEncoding];
        SDDState *state = self.states[name];
        NSAssert(state != nil, @"找不到名字为: %@ 的状态", name);
        
        return state;
    }
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

void SDDBuilderAddState(void* contextObj, sdd_state* raw_state) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    __weak SDDStateMachine* stateMachine = pcontext.stateMachine;
    __weak NSDictionary *actionBlocks = pcontext.actionBlocks;
    __weak id context = pcontext.runtimeContext;
    
    NSString* entries = [NSString stringWithCString:raw_state->entries encoding:NSUTF8StringEncoding];
    NSString* exits   = [NSString stringWithCString:raw_state->exits   encoding:NSUTF8StringEncoding];
    
    SDDActivation activation = ^(id<SDDEvent> event) {
        NSArray* acts = [entries sddNamedComponents];
        for (NSString* act in acts) {
            SEL simpleSel    = NSSelectorFromString(act);
            SEL augmentedSel = NSSelectorFromString([NSString stringWithFormat:@"%@:", act]);
            SDDAction action = actionBlocks[act];
            
            if (action) {
                action(event);
            } else if ([context respondsToSelector:simpleSel]) {
                SDDSimpleAction(context, simpleSel);
            } else if ([context respondsToSelector:augmentedSel]) {
                SDDAugmentedAction(context, augmentedSel, event);
            } else if (context != nil) {
                [[NSException exceptionWithName:@"SDDBuilderException"
                                         reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, act]
                                       userInfo:@{
                                                  @"context": context ? context : @"null",
                                                  @"action":  act,
                                                  }] raise];
            }

            if ([stateMachine.logger respondsToSelector:@selector(stateMachine:didCallMethod:)]) {
                [stateMachine.logger stateMachine:stateMachine didCallMethod:act];
            }
        }
    };

    SDDDeactivation deactivation = ^(id<SDDEvent> event) {
        NSArray* acts = [exits sddNamedComponents];
        for (NSString* act in acts) {
            SEL simpleSel    = NSSelectorFromString(act);
            SEL augmentedSel = NSSelectorFromString([NSString stringWithFormat:@"%@:", act]);
            SDDAction action = actionBlocks[act];

            if (action) {
                action(event);
            } else if ([context respondsToSelector:simpleSel]) {
                SDDSimpleAction(context, simpleSel);
            } else if ([context respondsToSelector:augmentedSel]) {
                SDDAugmentedAction(context, augmentedSel, event);
            } else if (context != nil) {
                [[NSException exceptionWithName:@"SDDBuilderException"
                                         reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, act]
                                       userInfo:@{
                                                  @"context": context ? context : @"null",
                                                  @"action":  act,
                                                  }] raise];
            }

            if ([stateMachine.logger respondsToSelector:@selector(stateMachine:didCallMethod:)]) {
                [stateMachine.logger stateMachine:stateMachine didCallMethod:act];
            }
        }
    };

    NSString* name = [NSString stringWithCString:raw_state->name encoding:NSUTF8StringEncoding];
    SDDState* state = [[SDDState alloc] initWithActivation:activation deactivation:deactivation];
    state.sddName = name;
    pcontext.states[name] = state;
    [pcontext.stateMachine addState:state];
}

void SDDBuilderSetDescendants(void* contextObj, sdd_state* raw_master, sdd_array* raw_descendants) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    
    SDDState* master = [pcontext stateWithRawState:raw_master];

    for (int i=0; i<sdd_array_count(raw_descendants); ++i) {
        sdd_state* raw_state = sdd_array_at(raw_descendants, i, YES);
        SDDState *ocState = [pcontext stateWithRawState:raw_state];
        [pcontext.stateMachine setParentState:master forChildState:ocState];
    }
}

void SDDBuilderMakeTransition(void* contextObj, sdd_transition* t) {
    __weak SDDParserContext *pcontext        = (__bridge SDDParserContext*)contextObj;
    __weak SDDStateMachine  *stateMachine    = pcontext.stateMachine;
    __weak NSDictionary     *conditionBlocks = pcontext.conditionBlocks;
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
                [[NSException exceptionWithName:@"SDDBuilderException"
                                         reason:[NSString stringWithFormat:@"无法在上下文:%@ 对象中找到 %@ 方法", context, act]
                                       userInfo:@{
                                                  @"context": context ? context : @"null",
                                                  @"action":  act,
                                                  }] raise];
            }

            if ([stateMachine.logger respondsToSelector:@selector(stateMachine:didCallMethod:)]) {
                [stateMachine.logger stateMachine:stateMachine didCallMethod:act];
            }
        }
    };
    
    NSString* conditions = [NSString stringWithCString:t->conditions encoding:NSUTF8StringEncoding];
    SDDCondition condition = ^BOOL (id<SDDEvent> event) {
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
                SDDCondition conditionBlock = conditionBlocks[p];
                
                if (conditionBlock) {
                    exprValue = conditionBlock(event);
                } else if ([context respondsToSelector:simpleSel]) {
                    exprValue = SDDConditionMsgSend(context, simpleSel);
                } else if ([context respondsToSelector:augmentedSel]) {
                    exprValue = SDDConditionMsgSend2(context, augmentedSel, event);
                } else if (context != nil) {
                    [[NSException exceptionWithName:@"SDDBuilderException"
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

    SDDState* fromState  = [pcontext stateWithCName:t->from];
    SDDState* toState    = [pcontext stateWithCName:t->to];
    
    NSString *prefix = (t->signal->type == SDD_SIG_INTERNAL) ? @"$" : @"";
    NSString* signalName = [prefix stringByAppendingString:[NSString stringWithCString:t->signal->name encoding:NSUTF8StringEncoding]];
    [pcontext.stateMachine when:signalName satisfied:condition transitFrom:fromState to:toState postAction:postAction];
}

void SDDBuilderTopStateCompletion(void *contextObj, sdd_state *raw_state) {
    __weak SDDParserContext* pcontext = (__bridge SDDParserContext*)contextObj;
    SDDState *topState = [pcontext stateWithCName:raw_state->name];
    [pcontext.stateMachine setTopState:topState];
    pcontext.stateMachine.sddName = [NSString stringWithUTF8String:raw_state->name];
}

void SDDBuilderParsingFinishCompletion(void *contextObj) {
    
}

@implementation SDDBuilder {
    id<SDDLogger>   _logger;
    SDDEventsPool  *_epool;
    NSMutableArray *_HSMs;  // Hierachical State Machine
    NSMutableDictionary *_actionBlocks;
    NSMutableDictionary *_conditionBlocks;
}

- (instancetype)initWithLogger:(id<SDDLogger>)logger epool:(SDDEventsPool *)epool {
    if (self = [super init]) {
        _logger       = logger;
        _epool        = epool;
        _HSMs         = [NSMutableArray array];
        _actionBlocks    = [NSMutableDictionary dictionary];
        _conditionBlocks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    for (SDDStateMachine *s in _HSMs) {
        [s stop];
    }
}

- (SDDStateMachine*)stateMachineWithContext:(id)context dsl:(NSString*)dsl {
    SDDStateMachine* stateMachine = [[SDDStateMachine alloc] initWithLogger:_logger];
    
    NSMutableDictionary* states = [NSMutableDictionary dictionary];
    SDDParserContext* pcontext  = [[SDDParserContext alloc] init];
    pcontext.states         = states;
    pcontext.runtimeContext = context;
    pcontext.stateMachine   = stateMachine;
    pcontext.actionBlocks    = _actionBlocks;
    pcontext.conditionBlocks = _conditionBlocks;
    
    sdd_parser_callback callback;
    callback.context = (__bridge void*)pcontext;
    callback.stateHandler      = &SDDBuilderAddState;
    callback.clusterHandler    = &SDDBuilderSetDescendants;
    callback.transitionHandler = &SDDBuilderMakeTransition;
    callback.topstateHandler   = &SDDBuilderTopStateCompletion;
    callback.completionHandler = &SDDBuilderParsingFinishCompletion;
    
    sdd_parse([dsl cStringUsingEncoding:NSUTF8StringEncoding], &callback);
    return stateMachine;
}

- (SDDStateMachine *)addStateMachineWithContext:(id)context dsl:(NSString *)dsl {
    // Supports multithreading. underlying __secret_builder is a global variable, thus machine building must be synchronized.
    SDDStateMachine *hsm;
    @synchronized (_HSMs) {
         hsm = [self stateMachineWithContext:context dsl:dsl]; 
    
        [_HSMs addObject:hsm];
        [_epool addSubscriber:hsm];
    }
    
    [hsm start];
    return hsm;
}

- (void)removeStateMachine:(SDDStateMachine *)hsm {
    [hsm stop];
    
    @synchronized (_HSMs) {
        [_epool removeSubscriber:hsm];
        [_HSMs removeObject:hsm];
    }
}

- (void)hookAction:(NSString *)action withBlock:(SDDAction)block {
    NSAssert(_actionBlocks[action] == nil, @"Can't override action %@", action);
    _actionBlocks[action] = block;
}

- (void)hookCondition:(NSString *)condition withBlock:(SDDCondition)block {
    NSAssert(_conditionBlocks[condition] == nil, @"Can't override condition %@", condition);
    _conditionBlocks[condition] = block;
}

@end
