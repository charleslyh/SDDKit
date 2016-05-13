//
//  SDDState.m
//  SDD
//
//  Created by 黎玉华 on 16/3/25.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "SDDScheduler.h"

#pragma mark -

@implementation SDDState {
    BOOL _activated;
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

- (void)activate:(id)param {
    NSAssert(!_activated, @"<%@> 状态不允许重复激活", self);
    
    _activation(param);
    _activated = YES;
}

- (void)deactivate {
    NSAssert(_activated, @"<%@> 状态尚未激活", self);
    
    _deactivation();
    _activated = NO;
}


@end


#pragma mark -

@interface SDDTransition : NSObject
@property (nonatomic, copy, readonly) SDDCondition condition;
@property (nonatomic, weak, readonly) SDDState* targetState;
@property (nonatomic, copy, readonly) SDDAction postAct;

- (id)init __attribute__((deprecated));
@end

@implementation SDDTransition

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithCondition:(SDDCondition)condition targetState:(SDDState*)state postAction:(SDDAction)action {
    if (self = [super init]) {
        _condition   = condition != NULL ? condition : ^BOOL (id _) { return YES; };
        _postAct     = action    != NULL ? action    : ^(id _){};
        _targetState = state;
    }
    return self;
}

@end


typedef NSMutableDictionary<SDDEvent*, NSMutableArray<SDDTransition*>*> SDDJumpTable;

@interface SDDState(NSCopying)<NSCopying> @end
@implementation SDDState(NSCopying)
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
@end


@interface SDDScheduler ()<SDDEventSubscriber> @end

@implementation SDDScheduler {
    NSOperationQueue* _queue;
    SDDEventsPool* _epool;
    
    NSMutableSet* _states;
    NSMutableDictionary<SDDState*, SDDJumpTable*>* _jumpTables;
    SDDState* _rootState;
    SDDState* _currentState;
    NSMutableDictionary* _parents;
    NSMutableDictionary* _defaults;
    NSMutableDictionary* _monoDescendants;
}

- (instancetype)initWithOperationQueue:(NSOperationQueue *)queue {
    if (self = [super init]) {
        _queue       = queue;
        _states      = [NSMutableSet set];
        _jumpTables  = [NSMutableDictionary dictionary];
        _parents     = [NSMutableDictionary dictionary];
        _defaults    = [NSMutableDictionary dictionary];
        _monoDescendants = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addState:(SDDState *)state {
    [_states addObject:state];
}

- (void)state:(SDDState *)parent addMonoStates:(NSArray<SDDState *> *)children {
    for (SDDState* state in children)
        _parents[state] = parent;
    
    if (_monoDescendants[parent] == nil)
        _monoDescendants[parent] = [NSMutableArray array];
    
    NSMutableArray* ownDescendants = _monoDescendants[parent];
    [ownDescendants addObjectsFromArray:children];
}

- (void)setState:(nonnull SDDState *)state defaultState:(nonnull SDDState*)defaultState {
    _defaults[state] = defaultState;
}

- (void)setRootState:(nonnull SDDState*)state {
    _rootState = state;
}

- (void)when:(SDDEvent *)event
   satisfied:(SDDCondition)condition
 transitFrom:(SDDState *)from
          to:(SDDState *)to
  postAction:(SDDAction)postAction
{
    NSAssert(event != nil, @"[%@] event参数不允许为nil", NSStringFromSelector(_cmd));
    NSAssert([_states containsObject:from], @"[%@] SDDScheduler尚未添加from状态:%@", NSStringFromSelector(_cmd), from);
    NSAssert([_states containsObject:to],   @"[%@] SDDScheduler尚未添加to状态:%@",   NSStringFromSelector(_cmd), to);
    
    if (condition == NULL)  condition  = ^BOOL (id _) { return YES; };
    if (postAction == NULL) postAction = ^(id _) {};
    
    NSMutableDictionary* table = _jumpTables[from];
    if (_jumpTables[from] == nil) {
        // 首次处理from状态时，需要为在跳转表中新增一个映射表
        table = [NSMutableDictionary dictionary];
        _jumpTables[from] = table;
    }
    
    NSMutableArray* transitions = table[event];
    if (transitions == nil) {
        // 对于指定状态的跳转表，如果首次处理某个事件，则需要新增一个跳转集
        transitions = [NSMutableArray array];
        table[event] = transitions;
    }
    
    SDDTransition* trans = [[SDDTransition alloc] initWithCondition:condition targetState:to postAction:postAction];
    [transitions addObject:trans];
}

- (void)onEvent:(SDDEvent *)event withParam:(id)param {
    /* 假设
     <a>
     [A]->[B]: E1 / generates E2
     <b>
     [C]->[D]: E1
     [C]->[F]: E2
     [D]->[G]: E2
     当E1激发时，系统行为会非常奇怪，<a>会由于E1转换到B，然后又激发了E2，而E2又导致<b>进入了F状态。但是，使用者更倾向于认为，既然E1先被激发，那么<b>应该先转换为D，而后，由于E2再转换到G。这类似于传统算法的“广度优先搜索”和“深度优先搜索”处理的问题。这里应该选择“广度优先”处理策略，也就是当E1激发时，应先把所有E1可能导致的转换全部处理完成，然后再处理可能产生的更多事件和转换。
     要实现这种语义，有很多种方案，例如使用独立线程+生产者、消费者机制等等。但是，本质上来说，其实这就是一个“排队”问题。所以，可以利用OC提供的Operation Queue机制更轻松地实现为：将所有可能导致Action，Event激发的行为“丢”到队列中处理，而不是立即执行。这样的话，即使有新的事件被激发，其触发的状态转换和Action都会再次被排队。而它们前面，肯定已经排好了此前E1激发的其它转换。
     */
    [_queue addOperationWithBlock:^{
        SDDTransition* trans;
        SDDState *trigger;
        NSArray* path = [self pathOfState:_currentState];
        for (NSInteger i=path.count - 1; i>=0; --i) {
            trigger = path[i];
            
            SDDJumpTable* jtable = _jumpTables[trigger];
            if (!jtable)
                continue;
            
            NSArray* transitions = jtable[event];
            for (SDDTransition* t in transitions) {
                if (t.condition(param)) {
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
            [self activateState:newState triggerState:trigger];
            trans.postAct(param);
        }
    }];
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
        NSArray* descendants   = _monoDescendants[next];
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
                descendants = _monoDescendants[next];
            }
        } else {
            break;
        }
    }

    return path;
}

- (void)activateState:(SDDState *)state triggerState:(SDDState *)triggerState {
    NSArray* currentPath = [self pathOfState:_currentState];
    NSArray* nextPath    = [self pathOfState:state];
    
    BOOL fullMatch   = (currentPath.count == nextPath.count) && (currentPath.lastObject == nextPath.lastObject);
    BOOL leafRefresh = triggerState == currentPath.lastObject;
    
    int lastSolidIdx;
    if (fullMatch) {
        if (leafRefresh) {
            lastSolidIdx = (currentPath.count - 1) - 1;
        } else {
            lastSolidIdx = [currentPath indexOfObject:triggerState];
        }
    } else {
        int lastEqualIdx = -1;
        for (int j=0, last = MIN(currentPath.count, nextPath.count); j<last ; ++j) {
            if (currentPath[j] == nextPath[j]) {
                lastEqualIdx = j;
            }
        }
        lastSolidIdx = MIN(lastEqualIdx, [currentPath indexOfObject:triggerState]);
    }
    
    for (int i=(int)currentPath.count - 1; i > lastSolidIdx; --i) {
        SDDState* s = currentPath[i];
        [s deactivate];
    }
    
    for (int i=lastSolidIdx+1; i < nextPath.count; ++i) {
        SDDState* s = nextPath[i];
        [s activate:nil];
    }
    
    _currentState = nextPath.lastObject;
}

- (void)startWithEventsPool:(SDDEventsPool*)epool {
    NSAssert(_currentState==nil, @"不允许重复执行SDDScheduler的[%@]方法", NSStringFromSelector(_cmd));
    NSAssert(_rootState != nil, @"[%@] rootState不允许为nil", NSStringFromSelector(_cmd));
    NSAssert([_states containsObject:_rootState], @"[%@] rootState必须为已添加的状态之一", NSStringFromSelector(_cmd));
    
    _epool = epool;
    [_epool addSubscriber:self];
    [self activateState:_rootState triggerState:nil];
}

- (void)stop {
    NSAssert(_currentState!=nil, @"执行[SDDSchdeuler stop]之前，请确保其已经运行");
    
    NSArray* currentPath = [self pathOfState:_currentState];
    for (int i=(int)currentPath.count - 1; i>=0; --i) {
        SDDState* s = currentPath[i];
        [s deactivate];
    }
    
    [_epool removeSubscriber:self];
    
    _currentState = nil;
    _epool = nil;
}

@end