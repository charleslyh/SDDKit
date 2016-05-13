//
//  SDDSchedulerTests.m
//  SDDSchedulerTests
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "SDDScheduler.h"
#import "SDDMockFlows.h"

@interface SDDState (Name)
@property (nonatomic) NSString* name;
@end


static void* kTestSDDStateNameKey = &kTestSDDStateNameKey;
@implementation SDDState (Name)

- (void)setName:(NSString *)name {
    objc_setAssociatedObject(self, kTestSDDStateNameKey, name, OBJC_ASSOCIATION_COPY);
}

- (NSString *)name {
    return objc_getAssociatedObject(self, kTestSDDStateNameKey);
}

- (NSString *)description {
    return self.name;
}

@end


@interface SDDSchedulerTests : XCTestCase
@end

@implementation SDDSchedulerTests {
    SDDMockFlows* _flows;
    SDDEventsPool* _epool;
    SDDScheduler* _scheduler;
    SDDState *A, *B, *C, *D, *E, *F, *G;
}

- (SDDState*)makeStateWithFlows:(__weak SDDMockFlows*)flows name:(NSString*)name preFlow:(NSString*)preflow postLFow:(NSString*)postflow {
    SDDState* s = [[SDDState alloc] initWithActivation:^(id _){ [flows addFlow:preflow]; } deactivation:^{ [flows addFlow:postflow]; }];
    [s setName:name];
    return s;
}

static BOOL (^SDDCondAllwaysTrue)(id) = ^BOOL (id _) { return YES; };
static void (^SDDNilPostAction)(id) = ^(id _){};

- (void)setUp {
    [super setUp];
    
    _flows = [[SDDMockFlows alloc] init];
    _epool = [SDDEventsPool defaultPool];
    _scheduler = [[SDDScheduler alloc] initWithOperationQueue:[SDDDirectExecutionQueue new]];

    A = [self makeStateWithFlows:_flows name:@"A" preFlow:@"a" postLFow:@"1"];
    B = [self makeStateWithFlows:_flows name:@"B" preFlow:@"b" postLFow:@"2"];
    C = [self makeStateWithFlows:_flows name:@"C" preFlow:@"c" postLFow:@"3"];
    D = [self makeStateWithFlows:_flows name:@"D" preFlow:@"d" postLFow:@"4"];
    E = [self makeStateWithFlows:_flows name:@"E" preFlow:@"e" postLFow:@"5"];
    F = [self makeStateWithFlows:_flows name:@"F" preFlow:@"f" postLFow:@"6"];
    G = [self makeStateWithFlows:_flows name:@"G" preFlow:@"g" postLFow:@"7"];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRunWithSingleState {
    [_scheduler addState:A];
    [_scheduler setRootState:A];
    
    [_scheduler startWithEventsPool:_epool];
    XCTAssertEqualObjects(_flows, @"a");
}

- (void)testTwoStandaloneStates {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler setRootState:A];
    [_scheduler setRootState:A];

    [_scheduler startWithEventsPool:_epool];
    XCTAssertEqualObjects(_flows, @"a");
}

- (void)testActivateHierarchicalStatesWithExplicitDefault {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler state:A addMonoStates:@[B]];
    [_scheduler setState:A defaultState:B];
    [_scheduler setRootState:A];
    
    [_scheduler startWithEventsPool:_epool];
    XCTAssertEqualObjects(_flows, @"ab");
}

- (void)testLeafRefreshAtRoot {
    [_scheduler addState:A];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:A to:A postAction:nil];

    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"a1a");
}

- (void)testLeafRefresh {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler state:A addMonoStates:@[B]];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:B to:B postAction:nil];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"ab2b");
}

- (void)testTransitFromParentToChild {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler state:A addMonoStates:@[B]];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:A to:B postAction:nil];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"ab2b");
}

- (void)testTransitFromParentToNoneDefaultChildState {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler state:A addMonoStates:@[B, C]];
    [_scheduler setState:A defaultState:B];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:A to:C postAction:nil];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"ab2c");
}

- (void)testLeafRefreshAcrossMultiStates {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler state:A addMonoStates:@[B]];
    [_scheduler state:B addMonoStates:@[C]];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:A to:C postAction:nil];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"abc32bc");
}

// [A [B d:[C] [C] [D]]]
// [A] -> [D]: E
- (void)testTransitFromRootWithCommonParentStates {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler addState:D];
    [_scheduler state:A addMonoStates:@[B]];
    [_scheduler state:B addMonoStates:@[C,D]];
    [_scheduler setState:B defaultState:C];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:A to:D postAction:nil];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"abc32bd");
}

- (void)testActivateHierarchicalStatesWithImplicitDefaultState {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler setRootState:A];
    [_scheduler state:A addMonoStates:@[B]];
    
    [_scheduler startWithEventsPool:_epool];
    XCTAssertEqualObjects(_flows, @"ab");
}

// [A [B [C]]]
- (void)testActivateHierarchicalStatesWithExplicitDefaultsAcrossMoreThanOneLevel {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler state:A addMonoStates:@[B]];
    [_scheduler state:B addMonoStates:@[C]];
    [_scheduler setState:A defaultState:C];
    [_scheduler setRootState:A];
    
    [_scheduler startWithEventsPool:_epool];
    XCTAssertEqualObjects(_flows, @"abc");
}

- (void)testTwoDescendantsWithoutDefault {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler state:A addMonoStates:@[B,C]];
    [_scheduler setRootState:A];
    
    XCTAssertThrows([_scheduler startWithEventsPool:_epool], @"状态如果拥有多于1个子状态，则必须明确指定default状态，否则应该抛出异常");
}

// [A d:[B] [B][C]]
// [B] -> [C]: E
- (void)testActivateHierachicalState1 {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler state:A addMonoStates:@[B,C]];
    [_scheduler setState:A defaultState:B];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:B to:C postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"ab2c");
}

// [A d:[B] [B][C [D]]]
// [B] -> [D]: E
- (void)testActivateHierachicalState2 {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler addState:D];
    [_scheduler state:A addMonoStates:@[B, C]];
    [_scheduler state:C addMonoStates:@[D]];
    [_scheduler setState:A defaultState:B];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:B to:D postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"ab2cd");
}

// [A d:[C] [B [C]][D]]
// [C] -> [D]: E
- (void)testActivateHierachicalState3 {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler addState:D];
    [_scheduler state:A addMonoStates:@[B, D]];
    [_scheduler state:B addMonoStates:@[C]];
    [_scheduler setState:A defaultState:C];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:C to:D postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"abc32d");
}

// [A d:[B] [B [C]] [D [E]]]
// [C] -> [E]: E
- (void)testActivateHierachicalState4 {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler addState:D];
    [_scheduler addState:E];
    [_scheduler state:A addMonoStates:@[B, D]];
    [_scheduler state:B addMonoStates:@[C]];
    [_scheduler state:D addMonoStates:@[E]];
    [_scheduler setState:A defaultState:C];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:C to:E postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"abc32de");
}

// [A d:[B] [B][C]]
// [A] -> [C]: E
- (void)testTransformFromSuperState {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler state:A addMonoStates:@[B,C]];
    [_scheduler setState:A defaultState:B];
    [_scheduler setRootState:A];
    [_scheduler when:@"E" satisfied:SDDCondAllwaysTrue transitFrom:A to:C postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"E" withParam:nil];
    XCTAssertEqualObjects(_flows, @"ab2c");
}

// [E d:[B] [D [A][C]] [B]]
// [B]->[A]: α
// [D]->[B]: β
// [A]->[C]: γ
// [B]->[C]: δ
- (void)testFig2_1 {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler addState:D];
    [_scheduler addState:E];
    [_scheduler state:E addMonoStates:@[B,D]];
    [_scheduler state:D addMonoStates:@[A,C]];
    [_scheduler setState:E defaultState:B];
    [_scheduler setRootState:E];
    
    [_scheduler when:@"α" satisfied:SDDCondAllwaysTrue transitFrom:B to:A postAction:SDDNilPostAction];
    [_scheduler when:@"β" satisfied:SDDCondAllwaysTrue transitFrom:D to:B postAction:SDDNilPostAction];
    [_scheduler when:@"γ" satisfied:SDDCondAllwaysTrue transitFrom:A to:C postAction:SDDNilPostAction];
    [_scheduler when:@"δ" satisfied:SDDCondAllwaysTrue transitFrom:B to:C postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"α" withParam:nil];
    [_epool scheduleEvent:@"γ" withParam:nil];
    [_epool scheduleEvent:@"β" withParam:nil];
    [_epool scheduleEvent:@"δ" withParam:nil];
    XCTAssertEqualObjects(_flows, @"eb2da1c34b2dc");
}

// [E d:[B] [D [A][C]] [B]]
// [B]->[A]: α
// [D]->[B]: β
// [A]->[C]: γ
// [B]->[C]: δ
- (void)testFig2_2 {
    [_scheduler addState:A];
    [_scheduler addState:B];
    [_scheduler addState:C];
    [_scheduler addState:D];
    [_scheduler addState:E];
    [_scheduler state:E addMonoStates:@[B,D]];
    [_scheduler state:D addMonoStates:@[A,C]];
    [_scheduler setState:E defaultState:B];
    [_scheduler setRootState:E];
    [_scheduler when:@"α" satisfied:SDDCondAllwaysTrue transitFrom:B to:A postAction:SDDNilPostAction];
    [_scheduler when:@"β" satisfied:SDDCondAllwaysTrue transitFrom:D to:B postAction:SDDNilPostAction];
    [_scheduler when:@"γ" satisfied:SDDCondAllwaysTrue transitFrom:A to:C postAction:SDDNilPostAction];
    [_scheduler when:@"δ" satisfied:SDDCondAllwaysTrue transitFrom:B to:C postAction:SDDNilPostAction];
    
    [_scheduler startWithEventsPool:_epool];
    [_epool scheduleEvent:@"α" withParam:nil];
    [_epool scheduleEvent:@"β" withParam:nil];
    [_epool scheduleEvent:@"γ" withParam:nil];
    [_epool scheduleEvent:@"δ" withParam:nil];
    [_scheduler stop];
    
    // 遇到被完全忽略的γ事件后，此前记录的状态被清空了，所以容易出现问题
    XCTAssertEqualObjects(_flows, @"eb2da14b2dc345");
}

@end
