//
//  SDDMachineBuilderTests.m
//  YYMSAuth
//
//  Created by 黎玉华 on 16/1/22.
//  Copyright © 2016年 YY.Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SDDI/SDDI.h>
#import "SDDMockFlows.h"

@interface SDDTestMachineBuilder : XCTestCase
@property (nonatomic) SDDMockFlows* flows;
@end

@implementation SDDTestMachineBuilder

- (void)performTestWithDSL:(NSString*)dsl expectedFlows:(NSString*)expectedFlows customActions:(void (^)(SDDEventsPool*))customActions {
    [self performTestWithDSL:dsl expectedFlows:expectedFlows initialArgument:nil customActions:customActions];
}

- (void)performTestWithDSL:(NSString*)dsl expectedFlows:(NSString*)expectedFlows initialArgument:(id)argument customActions:(void (^)(SDDEventsPool*))customActions {
    self.flows = [[SDDMockFlows alloc] init];
    
    SDDEventsPool* epool = [[SDDEventsPool alloc] init];
    SDDSchedulerBuilder* builder = [[SDDSchedulerBuilder alloc] initWithNamespace:@"" logger:nil queue:[SDDDirectExecutionQueue new]];
    SDDScheduler* scheduler = [builder schedulerWithContext:self
                                                        dsl:dsl];
    
    [scheduler startWithEventsPool:epool initialArgument:argument];
    
    if (customActions != NULL)
        customActions(epool);
    
    [scheduler stop];
    
    XCTAssertEqualObjects([_flows description], expectedFlows);
}

- (void)ma { [self.flows addFlow:@"a"]; }
- (void)mb { [self.flows addFlow:@"b"]; }
- (void)mc { [self.flows addFlow:@"c"]; }
- (void)md { [self.flows addFlow:@"d"]; }
- (void)me { [self.flows addFlow:@"e"]; }
- (void)mf { [self.flows addFlow:@"f"]; }
- (void)m1 { [self.flows addFlow:@"1"]; }
- (void)m2 { [self.flows addFlow:@"2"]; }
- (void)m3 { [self.flows addFlow:@"3"]; }
- (void)m4 { [self.flows addFlow:@"4"]; }
- (void)m5 { [self.flows addFlow:@"5"]; }
- (void)m6 { [self.flows addFlow:@"6"]; }
- (void)p1 { [self.flows addFlow:@"α"]; }
- (void)p2 { [self.flows addFlow:@"β"]; }
- (void)p3 { [self.flows addFlow:@"γ"]; }
- (void)p4 { [self.flows addFlow:@"δ"]; }

- (void)times2:(NSNumber*)number { [self.flows addFlow:[@([number integerValue] * 2) description]]; }
- (void)times3:(NSNumber*)number { [self.flows addFlow:[@([number integerValue] * 3) description]]; }
- (void)times4:(NSNumber*)number { [self.flows addFlow:[@([number integerValue] * 4) description]]; }


- (BOOL)yes { return YES; }
- (BOOL)no  { return NO;  }
- (BOOL)isOdd:(NSNumber*)number { return [number integerValue] & 1; }

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

- (void)testCluster2 {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1 ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab21" customActions:nil];
}

- (void)testCluster3 {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1 ~[C]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ac31" customActions:nil];
}

- (void)testSimpleTransit {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1 ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Event
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab2c31" customActions:^(SDDEventsPool* p){
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testTransitBack {
    NSString* const dsl = SDDOCLanguage
    (
     [A e:ma x:m1 ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Foward
     [C]->[B]: Back
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"ab2c3b21" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Foward"];
        [p scheduleEvent:@"Back"];
    }];
}


- (NSString*)Figure2_1 {
    return SDDOCLanguage
    (
     [E e:me x:m5 ~[B]
        [B e:mb x:m2]
        [D e:md x:m4
            [A e:ma x:m1]
            [C e:mc x:m3]
        ]
     ]
     
     [B]->[A]: E1
     [D]->[B]: E2
     [A]->[C]: E3
     [B]->[C]: E4
     );
}

- (void)testMultipleTransitions {
    [self performTestWithDSL:[self Figure2_1] expectedFlows:@"eb2da1c34b2dc345" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"E1"];
        [p scheduleEvent:@"E3"];
        [p scheduleEvent:@"E2"];
        [p scheduleEvent:@"E4"];
    }];
}

- (void)testMultipleTransitions2 {
    [self performTestWithDSL:[self Figure2_1] expectedFlows:@"eb2da14b2dc345" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"E1"];
        [p scheduleEvent:@"E2"];
        [p scheduleEvent:@"E3"];
        [p scheduleEvent:@"E4"];
    }];
}

- (void)testTransitWithCondition_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes)
    );

    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testTransitWithCondition_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalNOT_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (!no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalNOT_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (!yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalAnd_NO_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no & no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalAnd_NO_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no & yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalAnd_YES_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes & no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalAnd_YES_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes & yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalOr_NO_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no | no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalOr_NO_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalOr_YES_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes | no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalOr_YES_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalXOR_NO_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no ^ no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalXOR_NO_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (no ^ yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalXOR_YES_NO {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes ^ no)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testLogicalXOR_YES_YES {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B] -> [C]: Event (yes ^ yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testCompoundConditionWithoutParenthesis {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     // no & no | yes   => yes
     [B] -> [C]: Event (no & no | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testCompoundConditionWithParenthesis {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     // no & no | yes   => yes
     // no & (no | yes) => no
     // 括号应该改变运算优先级
     [B] -> [C]: Event (no & (no | yes))
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testTransitWithSinglePostAction {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]

     [B]->[C]: Event / p1
     );

    [self performTestWithDSL:dsl expectedFlows:@"b2cα3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testTransitWithMultiplePostActions {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Event / p1 p2
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2cαβ3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event"];
    }];
}

- (void)testTransitWithMultiplePostActionsAndEvents {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Event1 / p1 p2
     [C]->[B]: Event2 / p3
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2cαβ3bγ2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event1"];
        [p scheduleEvent:@"Event2"];
    }];
}

- (void)testTransitionWithNegativeConditionAndPostActions {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Trigger (no) / p1
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Trigger"];
    }];
}

- (void)testTransitionWithPositiveConditionAndPostActions {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Trigger (yes) / p3
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2cγ3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Trigger"];
    }];
}

- (void)testEventWithArgument {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb times2 x:p2]
      [C e:mc times3 x:p3]
      ]
     
     [B]->[C]: Trigger / times4
     );
    
    NSNumber* seven = @7;
    NSNumber* nine  = @9;
    [self performTestWithDSL:dsl expectedFlows:@"b18βc2128γ" initialArgument:nine customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Trigger" withParam:seven];
    }];
}

- (void)testConditionWithArgumentResultingPositive {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Event (isOdd)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event" withParam:@1];
    }];
}

- (void)testConditionWithArgumentResultingNegative {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Event (isOdd)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event" withParam:@2];
    }];
}

- (void)testAugmentedConditionAndSimpleCondition {
    NSString* const dsl = SDDOCLanguage
    (
     [A ~[B]
      [B e:mb x:m2]
      [C e:mc x:m3]
      ]
     
     [B]->[C]: Event (isOdd | yes)
     );
    
    [self performTestWithDSL:dsl expectedFlows:@"b2c3" customActions:^(SDDEventsPool* p) {
        [p scheduleEvent:@"Event" withParam:@2];
    }];
}

@end
