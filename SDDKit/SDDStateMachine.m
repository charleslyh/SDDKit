// SDDStateMachine.m
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

#import "SDDStateMachine.h"
#import "SDDLogger.h"


@interface SDDState(NSCopying)<NSCopying>
@end

@implementation SDDState {
    BOOL            _activated;
    SDDActivation   _activation;
    SDDDeactivation _deactivation;
}

- (id)initWithActivation:(SDDActivation)activation deactivation:(SDDDeactivation)deactivation {
    if (self = [super init]) {
        _activated = NO;
        _activation   = activation;
        _deactivation = deactivation;
    }
    return self;
}

- (void)activate:(id<SDDEvent>)event {
    NSAssert(!_activated, @"[SDD][%@] 状态不允许重复激活", self);
    
    _activation(event);
    _activated = YES;
}

- (void)deactivate:(id<SDDEvent>)event {
    NSAssert(_activated, @"[SDD][%@] 状态尚未激活", self);
    
    _deactivation(event);
    _activated = NO;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end


#pragma mark -

@interface SDDTransition : NSObject
@property (nonatomic, weak, readonly) SDDState* targetState;
@property (nonatomic, copy, readonly) SDDCondition condition;
@property (nonatomic, copy, readonly) SDDAction postAct;

- (id)init NS_UNAVAILABLE;
@end

@implementation SDDTransition

- (id)initWithCondition:(SDDCondition)condition targetState:(SDDState*)state postAction:(SDDAction)action {
    if (self = [super init]) {
        _condition   = (condition != NULL) ? condition : ^BOOL (id<SDDEvent> _) { return YES; };
        _postAct     = (action    != NULL) ? action    : ^(id<SDDEvent> _){};
        _targetState = state;
    }
    return self;
}

@end


typedef NSMutableDictionary<NSString *, NSMutableArray<SDDTransition*> *> SDDJumpTable;

@interface SDDNilLogger :NSObject <SDDLogger> @end
@implementation SDDNilLogger
- (void)stateMachine:(SDDStateMachine *)hsm didStartWithPath:(SDDPath *)path {}
- (void)stateMachine:(SDDStateMachine *)hsm didStopFromPath:(SDDPath *)path {}
- (void)stateMachine:(SDDStateMachine *)hsm didTransitFromPath:(SDDPath *)from toPath:(SDDPath *)to byEvent:(id<SDDEvent>)e {}
@end

@implementation SDDStateMachine {
    NSMutableSet* _states;
    SDDState*     _topState;
    SDDState*     _currentState;
    NSMutableDictionary* _parents;
    NSMutableDictionary* _defaults;
    NSMutableDictionary* _descendants;
    NSMutableDictionary<SDDState*, SDDJumpTable*>* _jumpTables;
}

- (instancetype)initWithLogger:(id<SDDLogger>)logger {
    if (self = [super init]) {
        _logger      = logger ? logger : [SDDNilLogger new];
        _states      = [NSMutableSet set];
        _jumpTables  = [NSMutableDictionary dictionary];
        _parents     = [NSMutableDictionary dictionary];
        _defaults    = [NSMutableDictionary dictionary];
        _descendants = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addState:(SDDState *)state {
    [_states addObject:state];
}

- (void)setParentState:(nonnull SDDState *)parent forChildState:(nonnull SDDState *)child {
    _parents[child] = parent;
    
    if (_descendants[parent] == nil)
        _descendants[parent] = [NSMutableArray array];
    
    NSMutableArray* ownDescendants = _descendants[parent];
    [ownDescendants addObject:child];
}

- (void)setTopState:(nonnull SDDState*)state {
    _topState = state;
}

- (BOOL)state:(SDDState *)state isDescentantOfAnotherState:(SDDState *)anotherState {
    SDDState *s = state;
    while(s != nil) {
        if (_parents[s] == anotherState) {
            return YES;
        }
        
        s = _parents[s];
    }
    
    return NO;
}

- (void)when:(NSString *)signalName
   satisfied:(SDDCondition)condition
 transitFrom:(SDDState *)from
          to:(SDDState *)to
  postAction:(SDDAction)postAction
{
    if ([signalName isEqualToString:@"$Initial"]) {
        NSAssert([self state:to isDescentantOfAnotherState:from], @"[%@] 必须是 [%@] 的后代状态", to, from);
        
        _defaults[from] = to;
        return;
    }
    
    NSAssert([_states containsObject:from], @"[%@] SDDStateMachine尚未添加from状态:%@", NSStringFromSelector(_cmd), from);
    NSAssert([_states containsObject:to],   @"[%@] SDDStateMachine尚未添加to状态:%@",   NSStringFromSelector(_cmd), to);
    
    if (condition == NULL)  condition  = ^BOOL (id<SDDEvent> _) { return YES; };
    if (postAction == NULL) postAction = ^(id<SDDEvent> _) {};
    
    NSMutableDictionary* table = _jumpTables[from];
    if (_jumpTables[from] == nil) {
        // 首次处理from状态时，需要为在跳转表中新增一个映射表
        table = [NSMutableDictionary dictionary];
        _jumpTables[from] = table;
    }
    
    NSMutableArray* transitions = table[signalName];
    if (transitions == nil) {
        // 对于指定状态的跳转表，如果首次处理某个事件，则需要新增一个跳转集
        transitions = [NSMutableArray array];
        table[signalName] = transitions;
    }
    
    SDDTransition* trans = [[SDDTransition alloc] initWithCondition:condition targetState:to postAction:postAction];
    [transitions addObject:trans];
}

- (void)didScheduleEvent:(id<SDDEvent>)event {
    SDDTransition* trans;
    SDDState *trigger;
    NSArray* path = [self pathOfState:_currentState];
    for (NSInteger i=path.count - 1; i>=0; --i) {
        trigger = path[i];
        
        SDDJumpTable* jtable = _jumpTables[trigger];
        if (!jtable)
            continue;
        
        NSArray* transitions = jtable[event.signalName];
        for (SDDTransition* t in transitions) {
            if (t.condition(event)) {
                trans = t;
                break;
            }
        }
        
        // 正常情况下，对于某个指定的Event，应该最多仅存在唯一的一个可用转换，即使“不小心”创造了多个，我们认为其行为是“未定义”的。从实现来说，我们只会选用第一个满足条件的转换，而弃用其它的。所以，保证这种唯一性，是上层状态机设计者的职责。
        if (trans)
            break;
    }
    
    SDDState* newState = trans.targetState;
    if (newState) {
        [self activateState:newState triggerState:trigger withEvent:event completion:^(NSArray *fromPath, NSArray *toPath) {
            trans.postAct(event);
            
            [_logger stateMachine:self didTransitFromPath:fromPath toPath:toPath byEvent:event];
        }];
    }
}

- (NSArray*)pathOfState:(SDDState *)state {
    NSMutableArray* path = [NSMutableArray array];
    
    SDDState* next = state;
    while (next) {
        [path insertObject:next atIndex:0];
        next = _parents[next];
    }

    next = state;
    while(next) {
        // 如果某个状态包含唯一的子状态，但又么有明确指定default状态，那需要隐式定义该状态为默认状态
        NSArray* descendants   = _descendants[next];
        SDDState* defaultState = _defaults[next];
        NSAssert(defaultState!=nil || descendants.count<=1, @"状态%@的后续状态无法确定", next);
        
        if (defaultState) {
            SDDState* visit = defaultState;
            NSInteger insertIdx = path.count;
            while(visit != next) {
                [path insertObject:visit atIndex:insertIdx];
                visit = _parents[visit];
            }
            next = defaultState;
        } else if (descendants.count == 1) {
            while (descendants.count == 1) {
                [path addObject:descendants.firstObject];
                next = descendants.firstObject;
                descendants = _descendants[next];
            }
        } else {
            break;
        }
    }

    return path;
}

- (void)activateState:(SDDState *)state
         triggerState:(SDDState *)triggerState
            withEvent:(id<SDDEvent>)event
           completion:(void (^)(NSArray* deactivates, NSArray* activates))completion
{
    NSArray* currentPath = [self pathOfState:_currentState];
    NSArray* nextPath    = [self pathOfState:state];
    
    BOOL fullMatch   = (currentPath.count == nextPath.count) && (currentPath.lastObject == nextPath.lastObject);
    BOOL leafRefresh = triggerState == currentPath.lastObject;
    
    NSInteger lastSolidIdx;
    if (fullMatch) {
        if (leafRefresh) {
            lastSolidIdx = (currentPath.count - 1) - 1;
        } else {
            lastSolidIdx = [currentPath indexOfObject:triggerState];
        }
    } else {
        NSInteger lastEqualIdx = -1;
        for (NSInteger j=0, last = MIN(currentPath.count, nextPath.count); j<last ; ++j) {
            if (currentPath[j] == nextPath[j]) {
                lastEqualIdx = j;
            }
        }
        
        // 在不同的实现中indexOfObject返回值是不一样的，static library配置中，它直接返回-1，所以一切正常
        // 但在framework配置中，它返回的是MAX_INT，从而导致 MIN(lastEqualIdx, [current indexOfObject:triggerState])不正确
        NSInteger triggerIdx = [currentPath indexOfObject:triggerState];
        if (triggerIdx == NSNotFound)
            triggerIdx = -1;
        
        lastSolidIdx = MIN(lastEqualIdx, triggerIdx);
    }
    
    NSMutableArray *activates = [NSMutableArray array];
    NSMutableArray *deactivates = [NSMutableArray array];
    
    for (int i = ((int)currentPath.count - 1); i > lastSolidIdx; i -= 1) {
        SDDState* s = currentPath[i];
        [s deactivate:event];

        [deactivates addObject:s];
    }
    
    for (NSInteger i = (lastSolidIdx + 1); i < nextPath.count; i += 1) {
        SDDState* s = nextPath[i];
        [s activate:event];

        [activates addObject:s];
    }
    
    _currentState = nextPath.lastObject;
    
    if (completion != NULL)
        completion(deactivates, activates);
}

- (void)start {
    NSAssert(_currentState==nil, @"不允许重复执行SDDStateMachine的[%@]方法", NSStringFromSelector(_cmd));
    NSAssert(_topState != nil, @"[%@] topState不允许为nil", NSStringFromSelector(_cmd));
    NSAssert([_states containsObject:_topState], @"[%@] topState必须为已添加的状态之一", NSStringFromSelector(_cmd));
    
    [self activateState:_topState triggerState:nil withEvent:SDDELiteral(SDDE_InitialTranition) completion:^(NSArray *_, NSArray *toPath) {
        [_logger stateMachine:self didStartWithPath:toPath];
    }];
}


- (void)stop {
    NSAssert(_currentState!=nil, @"执行[SDDStateMachine stop]之前，请确保其已经运行");
    
    [self activateState:nil triggerState:_currentState withEvent:SDDELiteral(SDDE_FinalTranition) completion:^(NSArray *fromPath, NSArray *_) {
        [_logger stateMachine:self didStopFromPath:fromPath];
    }];
    
    _currentState = nil;
}

@end
