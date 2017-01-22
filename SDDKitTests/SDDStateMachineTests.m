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

- (void)setUp {
    [super setUp];
    
    _epool = [[SDDEventsPool alloc] init];
    
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

    [_hsm start];
    XCTAssertEqualObjects(_flows, @"a");
}

/*
 [A [B]]
 [A] -> [B]: $Initial
 */
- (void)testActivateHierarchicalStatesWithExplicitInitial {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm setParentState:A forChildState:B];
    [_hsm setTopState:A];
    
    [_hsm when:@"$Initial" satisfied:nil transitFrom:_hsm.outterState to:B postAction:nil];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"ab");
}

- (void)testLeafRefreshAtRoot {
    [_hsm addState:A];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:nil transitFrom:A to:A postAction:nil];

    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];
    XCTAssertEqualObjects(_flows, @"a1a");
}

/*
 [A
   [B]
 ]
 [B] -> [B]: E
 */
- (void)testLeafRefresh {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm setParentState:A forChildState:B];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:nil transitFrom:B to:B postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];
    XCTAssertEqualObjects(_flows, @"ab2b");
}

- (void)testTransitFromParentToChild {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm setParentState:A forChildState:B];
    [_hsm setTopState:A];
    [_hsm when:@"E" satisfied:nil transitFrom:A to:B postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"ab2b");
}

/*
 [A
    [B]
    [C]
 ]
 [.] -> [B]: $Initial
 */
- (void)testTransitFromParentToNoneDefaultChildState {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:C];
    [_hsm setTopState:A];
    
    [_hsm when:@"$Initial" satisfied:nil transitFrom:_hsm.outterState to:B postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:A to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"ab2c");
}

/*
 [A
    [B
        [C]
    ]
 ]
 */
- (void)testLeafRefreshAcrossMultiStates {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:B forChildState:C];
    [_hsm setTopState:A];
    
    [_hsm when:@"E" satisfied:nil transitFrom:A to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"abc32bc");
}

/*
 [A
    [B
        [C]
        [D]
    ]
 ]

 [B] -> [C]: $Default
 [A] -> [D]: E
 */
- (void)testTransitFromRootWithCommonParentStates {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:B forChildState:C];
    [_hsm setParentState:B forChildState:D];
    [_hsm setTopState:A];

    [_hsm when:@"$Default" satisfied:nil transitFrom:B to:C postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:A to:D postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"abc32bd");
}

/*
 [A
    [B]
 ]
 */
- (void)testActivateHierarchicalStatesWithImplicitInitialTransition {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm setTopState:A];
    [_hsm setParentState:A forChildState:B];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"ab");
}

/*
 [A
    [B
        [C]
    ]
 ]
 [.] -> [C]: $Initial
 */
- (void)testActivateHierarchicalStatesWithExplicitInitialTransitionAcrossMultiLevels {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:B forChildState:C];
    [_hsm setTopState:A];
    
    [_hsm when:@"$Initial" satisfied:nil transitFrom:_hsm.outterState to:C postAction:nil];
    
    [_hsm start];
    XCTAssertEqualObjects(_flows, @"abc");
}

- (void)testTwoDescendantsWithoutProvidingExplicitInitialTransition {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:C];
    [_hsm setTopState:A];
    
    XCTAssertThrows([_hsm start], @"状态如果拥有多于1个子状态，则必须明确指定default状态，否则应该抛出异常");
}

/*
 [A
    [B]
    [C]
 ]
 [.] -> [B]: $Initial
 [B] -> [C]: E
 */
- (void)testActivateHierachicalState1 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:C];
    [_hsm setTopState:A];
    
    [_hsm when:@"$Initial" satisfied:nil transitFrom:_hsm.outterState to:B postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:B to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"ab2c");
}

/*
 [A
    [B]
    [C
        [D]
    ]
 ]
 [.] -> [B]: $Initial
 [B] -> [D]: E
 */
- (void)testActivateHierachicalState2 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:C];
    [_hsm setParentState:C forChildState:D];
    [_hsm setTopState:A];

    [_hsm when:@"$Initial" satisfied:nil transitFrom:_hsm.outterState to:B postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:B to:D postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"ab2cd");
}

/*
 [A
    [B
        [C]
    ]
    [D]
 ]
 [A] -> [C]: $Default
 [C] -> [D]: E
 */
- (void)testActivateHierachicalState3 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:D];
    [_hsm setParentState:B forChildState:C];
    [_hsm setTopState:A];

    [_hsm when:@"$Default" satisfied:nil transitFrom:A to:C postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:C to:D postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"abc32d");
}

/*
 [A
    [B [C]]
    [D [E]]
 ]
 [A] -> [B]: $Default
 [C] -> [E]: E
 */
- (void)testActivateHierachicalState4 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm addState:E];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:D];
    [_hsm setParentState:B forChildState:C];
    [_hsm setParentState:D forChildState:E];
    [_hsm setTopState:A];
    
    [_hsm when:@"$Default" satisfied:nil transitFrom:A to:B postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:C to:E postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"abc32de");
}


/*
 [A
    [B]
    [C]
 ]
 [A] -> [B]: $Default
 [A] -> [C]: E
 */
- (void)testTransitFromSuperState {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm setParentState:A forChildState:B];
    [_hsm setParentState:A forChildState:C];
    [_hsm setTopState:A];
    
    [_hsm when:@"$Default" satisfied:nil transitFrom:A to:B postAction:nil];
    [_hsm when:@"E" satisfied:nil transitFrom:A to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(E)];

    XCTAssertEqualObjects(_flows, @"ab2c");
}

/*
 [E
    [D
        [A]
        [C]
    ]
    [B]
 ]
 [E] -> [B]: $Default
 [B] -> [A]: Alpha
 [D] -> [B]: Beta
 [A] -> [C]: Gama
 [B] -> [C]: Delta
 */
- (void)testFig2_1 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm addState:E];
    [_hsm setParentState:E forChildState:B];
    [_hsm setParentState:E forChildState:D];
    [_hsm setParentState:D forChildState:A];
    [_hsm setParentState:D forChildState:C];
    [_hsm setTopState:E];
    
    [_hsm when:@"$Default" satisfied:nil transitFrom:E to:B postAction:nil];
    [_hsm when:@"Alpha" satisfied:nil transitFrom:B to:A postAction:nil];
    [_hsm when:@"Beta"  satisfied:nil transitFrom:D to:B postAction:nil];
    [_hsm when:@"Gama"  satisfied:nil transitFrom:A to:C postAction:nil];
    [_hsm when:@"Delta" satisfied:nil transitFrom:B to:C postAction:nil];
    
    [_hsm start];
    [_epool scheduleEvent:SDDELiteral(Alpha)];
    [_epool scheduleEvent:SDDELiteral(Gama)];
    [_epool scheduleEvent:SDDELiteral(Beta)];
    [_epool scheduleEvent:SDDELiteral(Delta)];

    XCTAssertEqualObjects(_flows, @"eb2da1c34b2dc");
}

/*
 [E
    [D
        [A]
        [C]
    ]
    [B]
 ]
 [E] -> [B]: $Default
 [B] -> [A]: Alpha
 [D] -> [B]: Beta
 [A] -> [C]: Gama
 [B] -> [C]: Delta
*/
- (void)testFig2_2 {
    [_hsm addState:A];
    [_hsm addState:B];
    [_hsm addState:C];
    [_hsm addState:D];
    [_hsm addState:E];
    [_hsm setParentState:E forChildState:B];
    [_hsm setParentState:E forChildState:D];
    [_hsm setParentState:D forChildState:A];
    [_hsm setParentState:D forChildState:C];
    [_hsm setTopState:E];

    [_hsm when:@"$Default" satisfied:nil transitFrom:E to:B postAction:nil];
    [_hsm when:@"Alpha" satisfied:nil transitFrom:B to:A postAction:nil];
    [_hsm when:@"Beta"  satisfied:nil transitFrom:D to:B postAction:nil];
    [_hsm when:@"Gama"  satisfied:nil transitFrom:A to:C postAction:nil];
    [_hsm when:@"Delta" satisfied:nil transitFrom:B to:C postAction:nil];
    
    [_hsm start];
    
    [_epool scheduleEvent:SDDELiteral(Alpha)];
    [_epool scheduleEvent:SDDELiteral(Beta)];
    [_epool scheduleEvent:SDDELiteral(Gama)];
    [_epool scheduleEvent:SDDELiteral(Delta)];

    [_hsm stop];
    // 遇到被完全忽略的Gama事件后，此前记录的状态被清空了，所以容易出现问题
    XCTAssertEqualObjects(_flows, @"eb2da14b2dc345");
}

@end
