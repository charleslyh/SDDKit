//
//  SDDBuilderTests.m
//  SDDKitTests
//
//  Created by 黎玉华 on 16/1/22.
//  Copyright © 2016年 CharlesLeeInc. All rights reserved.
//

#import "SDDKit.h"
#import "SDDMockFlows.h"
#import <XCTest/XCTest.h>

@interface SDDBuilderDSLTests : XCTestCase
@property (nonatomic) SDDMockFlows* flows;
@end

@implementation SDDBuilderDSLTests {
    SDDEventsPool *_epool;
}

- (void)setUp {
    [super setUp];

    _epool = [[SDDEventsPool alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)performTestWithDSL:(NSString*)dsl expectedFlows:(NSString*)expectedFlows customActions:(void (^)())customActions {
    [self performTestWithDSL:dsl expectedFlows:expectedFlows initialParam:nil customActions:customActions];
}

- (void)performTestWithDSL:(NSString*)dsl expectedFlows:(NSString*)expectedFlows initialParam:(id)param customActions:(void (^)())customActions {
    self.flows = [[SDDMockFlows alloc] init];
    
    // In order to trigger -[SDDBuilder dealloc] method, we have to put the hole process into an auto release pool
    @autoreleasepool {
        SDDBuilder* builder = [[SDDBuilder alloc] initWithLogger:nil epool:_epool];
        [builder addStateMachineWithContext:self dsl:dsl];
        
        if (customActions != nil) {
            customActions();
        }
    }
    
    XCTAssertEqualObjects(_flows, expectedFlows);
}

- (void)ma { [self.flows markItem:@"a"]; }
- (void)mb { [self.flows markItem:@"b"]; }
- (void)mc { [self.flows markItem:@"c"]; }
- (void)md { [self.flows markItem:@"d"]; }
- (void)me { [self.flows markItem:@"e"]; }
- (void)mf { [self.flows markItem:@"f"]; }
- (void)m1 { [self.flows markItem:@"1"]; }
- (void)m2 { [self.flows markItem:@"2"]; }
- (void)m3 { [self.flows markItem:@"3"]; }
- (void)m4 { [self.flows markItem:@"4"]; }
- (void)m5 { [self.flows markItem:@"5"]; }
- (void)m6 { [self.flows markItem:@"6"]; }
- (void)p1 { [self.flows markItem:@"α"]; }
- (void)p2 { [self.flows markItem:@"β"]; }
- (void)p3 { [self.flows markItem:@"γ"]; }
- (void)p4 { [self.flows markItem:@"δ"]; }

- (void)times2:(SDDELiteralEvent *)e { [self.flows markItem:[@([e.param integerValue] * 2) description]]; }
- (void)times3:(SDDELiteralEvent *)e { [self.flows markItem:[@([e.param integerValue] * 3) description]]; }
- (void)times4:(SDDELiteralEvent *)e { [self.flows markItem:[@([e.param integerValue] * 4) description]]; }


- (BOOL)yes { return YES; }
- (BOOL)no  { return NO;  }
- (BOOL)isOdd:(SDDELiteralEvent *)e { return [e.param integerValue] & 1; }

- (void)testSingleRootState {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1]
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"a1" customActions:nil];
}

- (void)testSingleStateWithMultipleEntries {
    NSString* const dsl = SDDOCLanguage
    (
     [A e: ma mb mc]
    );
    
    [self performTestWithDSL:dsl expectedFlows:@"abc" customActions:nil];
}

- (void)testSingleStateWithEntrieAndExit {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1]
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"a1" customActions:nil];
}

- (void)testSingleStateWithEntriesAndExits {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma mb x:m1 m2]
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab12" customActions:nil];
}

- (void)testSimpleCluster {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1
      [B e:mb x:m2]
      ]
     );

    [self performTestWithDSL:dsl expectedFlows:@"ab21" customActions:nil];
}

- (void)testMultiSubstatesWithProvidedTopInitialTransition {
    NSString *const dsl = SDDOCLanguage
    (
     [A e:ma x:m1
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [.] -> [B]: $Initial
    );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab21" customActions:nil];
}

- (void)testSimpleTransit {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [.]->[B]: $Initial
     [B]->[C]: E1
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab2c31" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testTransitBack {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A]->[B]: $Default
     
     [B]->[C]: Forward
     [C]->[B]: Backward
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab2c3b21" customActions:^{
        [_epool scheduleEvent:SDDELiteral(Forward)];
        [_epool scheduleEvent:SDDELiteral(Backward)];
    }];
}


- (NSString*)Figure2_1 {
    return SDDOCLanguage
    (
     [E e:me x:m5
        [B e:mb x:m2]
        [D e:md x:m4
            [A e:ma x:m1]
            [C e:mc x:m3]
        ]
     ]
     
     [E]->[B]: $Default
     
     [B]->[A]: E1
     [D]->[B]: E2
     [A]->[C]: E3
     [B]->[C]: E4
     );
}

- (void)testMultipleTransitions {
    [self performTestWithDSL:[self Figure2_1] expectedFlows:@"eb2da1c34b2dc345" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
        [_epool scheduleEvent:SDDELiteral(E3)];
        [_epool scheduleEvent:SDDELiteral(E2)];
        [_epool scheduleEvent:SDDELiteral(E4)];
    }];
}

- (void)testMultipleTransitions2 {
    [self performTestWithDSL:[self Figure2_1] expectedFlows:@"eb2da14b2dc345" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
        [_epool scheduleEvent:SDDELiteral(E2)];
        [_epool scheduleEvent:SDDELiteral(E3)];
        [_epool scheduleEvent:SDDELiteral(E4)];
    }];
}

- (void)testTransitWithCondition_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A]->[B]: $Default
     [B]->[C]: E1 (yes)
    );

    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testTransitWithCondition_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalNOT_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (!no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalNOT_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (!yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalAnd_NO_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no & no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalAnd_NO_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no & yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalAnd_YES_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes & no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalAnd_YES_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes & yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalOr_NO_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no | no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalOr_NO_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalOr_YES_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes | no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalOr_YES_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalXOR_NO_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no ^ no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalXOR_NO_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no ^ yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalXOR_YES_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes ^ no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testLogicalXOR_YES_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes ^ yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testCompoundConditionWithoutParenthesis {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     
     // no & no | yes   => yes
     [B] -> [C]: E1 (no & no | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testCompoundConditionWithParenthesis {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     
     // no & no | yes   => yes
     // no & (no | yes) => no
     // 括号应该改变运算优先级
     [B] -> [C]: E1 (no & (no | yes))
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testTransitWithSinglePostAction {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]

     [A] -> [B]: $Default
     [B] -> [C]: E1 / p1
     );

    [self performTestWithDSL:dsl expectedFlows:@"b2cα3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testTransitWithMultiplePostActions {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 / p1 p2
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2cαβ3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testTransitWithMultiplePostActionsAndEvents {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 / p1 p2
     [C] -> [B]: E2 / p3
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2cαβ3bγ2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
        [_epool scheduleEvent:SDDELiteral(E2)];
    }];
}

- (void)testTransitionWithNegativeConditionAndPostActions {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (no) / p1
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testTransitionWithPositiveConditionAndPostActions {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (yes) / p3
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2cγ3" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testEventWithArgument {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb times2 x:p2]
      [C e:mc times3 x:p3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 / times4
     );
    
    NSNumber* seven = @7;
    [self performTestWithDSL:dsl expectedFlows:@"b0βc2128γ" customActions:^{
        [_epool scheduleEvent:SDDELiteral2(E1, seven)];
    }];
}

- (void)testConditionWithArgumentResultingPositive {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (isOdd)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral2(E1, @1)];
    }];
}

- (void)testConditionWithArgumentResultingNegative {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (isOdd)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^{
        [_epool scheduleEvent:SDDELiteral2(E1, @2)];
    }];
}

- (void)testAugmentedConditionAndSimpleCondition {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1 (isOdd | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^{
        [_epool scheduleEvent:SDDELiteral2(E1, @2)];
    }];
}

- (void)markArgument:(SDDELiteralEvent *)literal {
    [self.flows markItem:literal.param];
}

- (void)testMarkDeactivatingArgument {
    NSString* const dsl = SDDOCLanguage
    (
     [A
      [B x:markArgument]
      [C]
      ]
     
     [A] -> [B]: $Default
     [B] -> [C]: E1
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"LastArgument" customActions:^{
        [_epool scheduleEvent:SDDELiteral2(E1, @"LastArgument")];
    }];
}

- (void)scheduleE2 { [_epool scheduleEvent:SDDELiteral(E2)]; }
- (void)scheduleE3 { [_epool scheduleEvent:SDDELiteral(E3)]; }
- (void)scheduleE4 { [_epool scheduleEvent:SDDELiteral(E4)]; }

- (void)testTripleTransitionCausedByOneEvent {
    NSString* const dsl = SDDOCLanguage
    (
     [Top
      [A e: ma]
      [B e: mb]
      [C e: mc]
      [D e: md]
      ]
     
     [Top] -> [A]: $Default
     [A] -> [B]: E1 / scheduleE2
     [B] -> [C]: E2 / scheduleE3
     [C] -> [D]: E3 / scheduleE4
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"abcd" customActions:^{
        [_epool scheduleEvent:SDDELiteral(E1)];
    }];
}

- (void)testInitialTransitionFromOutterState {
    NSString * const dsl = SDDOCLanguage
    (
    [Top
     [A e: ma x: m1]
     [B e: mb x: m2]
     ]
     
     [.] -> [B]: $Initial
    );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:nil];
}

- (void)testInitialTransitionFromOutterStateIntoDeepDescendant {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: ma x: m1]
      [B e: mb x: m2
           [C e: mc x: m3]
      ]
     ]
     
     [.] -> [C]: $Initial
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"bc32" customActions:nil];
}

- (void)testInitialTransitionAlongWithTopStateDefaultTransition {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: ma x: m1]
      [B e: mb x: m2]
      ]
     
     [.]   -> [B]: $Initial
     [Top] -> [A]: $Default
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:nil];
}

- (void)testDuplicatedOutterInitialTransition {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: ma x: m1]
      [B e: mb x: m2]
      ]
     
     [.] -> [B]: $Initial
     [.] -> [A]: $Initial
     );
    
    XCTAssertThrows([self performTestWithDSL:dsl expectedFlows:@"" customActions:nil]);
}


- (void)testDuplicatedDefaultTransitions {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: ma x: m1]
      [B e: mb x: m2]
      ]
     
     [Top] -> [B]: $Initial
     [Top] -> [A]: $Initial
     );
    
    XCTAssertThrows([self performTestWithDSL:dsl expectedFlows:@"" customActions:nil]);
}

- (void)testHookingSingleEntryAction {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: hook]
      ]
     );
    
    __block BOOL hooked = NO;
    SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
    [builder hookAction:@"hook" withBlock:^(id<SDDEvent> _) {
        hooked = YES;
    }];
    
    [builder addStateMachineWithContext:nil dsl:dsl];
    XCTAssertEqual(hooked, YES, "Hooked action should be executed");
}

- (void)testHookingMultipleEntryActions {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: act1 act2]
      ]
     );

    NSMutableArray *items = [NSMutableArray array];
    SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
    [builder hookAction:@"act1" withBlock:^(id<SDDEvent> _) {
        [items addObject:@1];
    }];

    [builder hookAction:@"act2" withBlock:^(id<SDDEvent> _) {
        [items addObject:@2];
    }];
    
    [builder addStateMachineWithContext:nil dsl:dsl];
    NSArray *expectedItems = @[@1, @2];
    XCTAssertEqualObjects(items, expectedItems);
}

- (void)testHookingSingleExitAction {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A x: hook]
      ]
     );
    
    __block BOOL hooked = NO;
    
    // In order to trigger exit action, these should be wrapped in an autoreleasepool.
    @autoreleasepool {
        SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
        [builder hookAction:@"hook" withBlock:^(id<SDDEvent> _) {
            hooked = YES;
        }];

        [builder addStateMachineWithContext:nil dsl:dsl];
    }
    
    XCTAssertEqual(hooked, YES, "Hooked action should be executed");
}

- (void)testHookingMultipleExitActions {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A x: act1 act2]
      ]
     );
    
    NSMutableArray *items = [NSMutableArray array];
    @autoreleasepool {
        SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
        [builder hookAction:@"act1" withBlock:^(id<SDDEvent> _) {
            [items addObject:@1];
        }];
        
        [builder hookAction:@"act2" withBlock:^(id<SDDEvent> _) {
            [items addObject:@2];
        }];
        
        [builder addStateMachineWithContext:nil dsl:dsl];
    }
    
    NSArray *expectedItems = @[@1, @2];
    XCTAssertEqualObjects(items, expectedItems);
}

- (void)testHookingEntryAndExitActions {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
        [A e: act1 x: act3]
     ]
     );
    
    NSMutableArray *items = [NSMutableArray array];
    @autoreleasepool {
        SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
        [builder hookAction:@"act1" withBlock:^(id<SDDEvent> _) {
            [items addObject:@1];
        }];
        
        [builder hookAction:@"act3" withBlock:^(id<SDDEvent> _) {
            [items addObject:@3];
        }];
        
        [builder addStateMachineWithContext:nil dsl:dsl];
    }
    
    NSArray *expectedItems = @[@1, @3];
    XCTAssertEqualObjects(items, expectedItems);
}

- (void)testDuplicationActionHooking {
    SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
    [builder hookAction:@"act1" withBlock:^(id<SDDEvent> _) {}];
    XCTAssertThrows([builder hookAction:@"act1" withBlock:^(id<SDDEvent> _) {}]);
}

- (void)testHookingCondition {
    NSString * const dsl = SDDOCLanguage
    (
     [Top
      [A e: act1]
      [B e: act2]
      ]
     [.] -> [A]: $Initial
     
     [A] -> [B]: E1 (guardWithYES)
     [B] -> [A]: E2 (!guardWithNO)
     );
    
    NSMutableArray *items = [NSMutableArray array];
    @autoreleasepool {
        SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
        [builder hookAction:@"act1" withBlock:^(id<SDDEvent> _) {
            [items addObject:@1];
        }];
        
        [builder hookAction:@"act2" withBlock:^(id<SDDEvent> _) {
            [items addObject:@2];
        }];
        
        [builder hookCondition:@"guardWithYES" withBlock:^BOOL(id<SDDEvent> e) {
            return YES;
        }];
        
        [builder hookCondition:@"guardWithNO" withBlock:^BOOL(id<SDDEvent> e) {
            return NO;
        }];
        
        [builder addStateMachineWithContext:nil dsl:dsl];
        [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(E1)];
        [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(E2)];
    }
    
    NSArray *expectedItems = @[@1, @2, @1];
    XCTAssertEqualObjects(items, expectedItems);
}

- (void)testHookingDuplicationCondition {
    SDDBuilder *builder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
    [builder hookCondition:@"guard" withBlock:^BOOL(id<SDDEvent> e) { return YES; }];
    XCTAssertThrows([builder hookCondition:@"guard" withBlock:^BOOL(id<SDDEvent> e) {
        return YES;
    }]);
}

@end
