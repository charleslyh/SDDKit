//
//  SDDStateMachineTests.m
//  SDDKitTests
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 CharlesLee Inc. All rights reserved.
//

#import "SDDKit.h"
#import "SDDMockFlows.h"

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

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

@end

@interface SDDSchedulerTests : XCTestCase
@end

@implementation SDDSchedulerTests {
    SDDMockFlows*    _flows;
    SDDEventsPool*   _epool;
    SDDStateMachine* _hsm;
    SDDState *A, *B, *C, *D, *E, *F, *G;
}

- (SDDState*)makeStateWithFlows:(__weak SDDMockFlows*)flows name:(NSString*)name preFlow:(NSString*)preflow postLFow:(NSString*)postflow {
    SDDState* s = [[SDDState alloc] initWithActivation:^(id _){ [flows markItem:preflow]; } deactivation:^(id _) { [flows markItem:postflow]; }];
    [s setName:name];
    return s;
}

static BOOL (^AllwaysYES)(id) = ^BOOL (id _) { return YES; };
static void (^SDDNilPostAction)(id) = ^(id _){};

- (void)setUp {
    [super setUp];
    
    _epool = [[SDDEventsPool alloc] init];
    [_epool open];
    
    _flows = [[SDDMockFlows alloc] init];
    _hsm = [[SDDStateMachine alloc] initWithLogger:nil];
    [_epool addSubscriber:_hsm];

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
    [_epool removeSubscriber:_hsm];
    [_epool close];
}

- (void)testRunWithSingleState {
    [_hsm addState:A];
    [_hsm setTopState:A];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"a");
}

- (void)testTwoStandaloneStates {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm setTopState:A];
    [_hsm setTopState:A];

    [_hsm start];
    XCTAssertEqualObjects(_flows, @"a");
}

- (void)testActivateHierarchicalStatesWithExplicitDefault {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm state:A addMonoStates:@[B]];
    [_hsm setState:A defaultState:B];
    [_hsm setTopState:A];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"ab");
}

- (void)testLeafRefreshAtRoot {
    [_hsm addState:A];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:A to:A postAction:nil];

    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];
    XCTAssertEqualObjects(_flows, @"a1a");
}

// [A
//   [B]
// ]
//
// [B] -> [B]: E
- (void)testLeafRefresh {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm state:A addMonoStates:@[B]];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:B to:B postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];
    XCTAssertEqualObjects(_flows, @"ab2b");
}

- (void)testTransitFromParentToChild {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm state:A addMonoStates:@[B]];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:A to:B postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"ab2b");
}

- (void)testTransitFromParentToNoneDefaultChildState {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm state:A addMonoStates:@[B, C]];
    [_hsm setState:A defaultState:B];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:A to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"ab2c");
}

- (void)testLeafRefreshAcrossMultiStates {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm state:A addMonoStates:@[B]];
    [_hsm state:B addMonoStates:@[C]];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:A to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"abc32bc");
}

// [A [B d:[C] [C] [D]]]
// [A] -> [D]: E
- (void)testTransitFromRootWithCommonParentStates {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm state:A addMonoStates:@[B]];
    [_hsm state:B addMonoStates:@[C,D]];
    [_hsm setState:B defaultState:C];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:A to:D postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"abc32bd");
}

- (void)testActivateHierarchicalStatesWithImplicitDefaultState {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm setTopState:A];
    [_hsm state:A addMonoStates:@[B]];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"ab");
}

// [A [B [C]]]
- (void)testActivateHierarchicalStatesWithExplicitDefaultsAcrossMoreThanOneLevel {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm state:A addMonoStates:@[B]];
    [_hsm state:B addMonoStates:@[C]];
    [_hsm setState:A defaultState:C];
    [_hsm setTopState:A];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"abc");
}

- (void)testTwoDescendantsWithoutDefault {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm state:A addMonoStates:@[B,C]];
    [_hsm setTopState:A];
    
    XCTAssertThrows([_hsm start], @"状态如果拥有多于1个子状态，则必须明确指定default状态，否则应该抛出异常");
}

// [A d:[B] [B][C]]
// [B] -> [C]: E
- (void)testActivateHierachicalState1 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm state:A addMonoStates:@[B,C]];
    [_hsm setState:A defaultState:B];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:B to:C postAction:SDDNilPostAction];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"ab2c");
}

// [A d:[B] [B][C [D]]]
// [B] -> [D]: E
- (void)testActivateHierachicalState2 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm state:A addMonoStates:@[B, C]];
    [_hsm state:C addMonoStates:@[D]];
    [_hsm setState:A defaultState:B];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:B to:D postAction:SDDNilPostAction];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"ab2cd");
}

// [A d:[C] [B [C]][D]]
// [C] -> [D]: E
- (void)testActivateHierachicalState3 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm state:A addMonoStates:@[B, D]];
    [_hsm state:B addMonoStates:@[C]];
    [_hsm setState:A defaultState:C];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:C to:D postAction:SDDNilPostAction];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"abc32d");
}

// [A d:[B] [B [C]] [D [E]]]
// [C] -> [E]: E
- (void)testActivateHierachicalState4 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm addState:E];
    [_hsm state:A addMonoStates:@[B, D]];
    [_hsm state:B addMonoStates:@[C]];
    [_hsm state:D addMonoStates:@[E]];
    [_hsm setState:A defaultState:C];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:C to:E postAction:SDDNilPostAction];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"abc32de");
}

// [A d:[B] [B][C]]
// [A] -> [C]: E
- (void)testTransformFromSuperState {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm state:A addMonoStates:@[B,C]];
    [_hsm setState:A defaultState:B];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:AllwaysYES transitFrom:A to:C postAction:SDDNilPostAction];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"ab2c");
}

// [E d:[B] [D [A][C]] [B]]
// [B]->[A]: Alpha
// [D]->[B]: Beta
// [A]->[C]: Gama
// [B]->[C]: Delta
- (void)testFig2_1 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm addState:E];
    [_hsm state:E addMonoStates:@[B,D]];
    [_hsm state:D addMonoStates:@[A,C]];
    [_hsm setState:E defaultState:B];
    [_hsm setTopState:E];
    
    [_hsm when:@"Alpha" satisfied:AllwaysYES transitFrom:B to:A postAction:SDDNilPostAction];
    [_hsm when:@"Beta"  satisfied:AllwaysYES transitFrom:D to:B postAction:SDDNilPostAction];
    [_hsm when:@"Gama"  satisfied:AllwaysYES transitFrom:A to:C postAction:SDDNilPostAction];
    [_hsm when:@"Delta" satisfied:AllwaysYES transitFrom:B to:C postAction:SDDNilPostAction];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(Alpha)];
    [_epool scheduleEvent:SDDELiteral(Gama)];
    [_epool scheduleEvent:SDDELiteral(Beta)];
    [_epool scheduleEvent:SDDELiteral(Delta) waitUntilDone:YES];

    XCTAssertEqualObjects(_flows, @"eb2da1c34b2dc");
}

// [E ~[B]
//  [D
//   [A][C]
//  ]
//  [B]
// ]
// [B]->[A]: Alpha
// [D]->[B]: Beta
// [A]->[C]: Gama
// [B]->[C]: Delta
- (void)testFig2_2 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm addState:E];
    [_hsm state:E addMonoStates:@[B,D]];
    [_hsm state:D addMonoStates:@[A,C]];
    [_hsm setState:E defaultState:B];
    [_hsm setTopState:E];
    [_hsm when:@"Alpha" satisfied:AllwaysYES transitFrom:B to:A postAction:SDDNilPostAction];
    [_hsm when:@"Beta"  satisfied:AllwaysYES transitFrom:D to:B postAction:SDDNilPostAction];
    [_hsm when:@"Gama"  satisfied:AllwaysYES transitFrom:A to:C postAction:SDDNilPostAction];
    [_hsm when:@"Delta" satisfied:AllwaysYES transitFrom:B to:C postAction:SDDNilPostAction];
    
    [_hsm start];
    
    [_epool scheduleEvent:SDDELiteral(Alpha)];
    [_epool scheduleEvent:SDDELiteral(Beta)];
    [_epool scheduleEvent:SDDELiteral(Gama)];
    [_epool scheduleEvent:SDDELiteral(Delta) waitUntilDone:YES];

    [_hsm stop];
    // 遇到被完全忽略的Gama事件后，此前记录的状态被清空了，所以容易出现问题
    XCTAssertEqualObjects(_flows, @"eb2da14b2dc345");
}

@end
