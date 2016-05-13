//
//  SDDMachineBuilderTests.m
//  YYMSAuth
//
//  Created by 黎玉华 on 16/1/22.
//  Copyright © 2016年 YY.Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SDDSchedulerBuilder.h"
#import "SDDEventsPool.h"
#import "SDDScheduler.h"
#import "SDDMockFlows.h"

@interface SDDTestMachineBuilder : XCTestCase
@property (nonatomic) SDDMockFlows* flows;
@end

@implementation SDDTestMachineBuilder

- (void)performTestWithDSL:(NSString*)dsl expectedFlows:(NSString*)expectedFlows customActions:(void (^)(SDDEventsPool*))customActions {
    self.flows = [[SDDMockFlows alloc] init];
    
    SDDEventsPool* epool = [[SDDEventsPool alloc] init];
    SDDSchedulerBuilder* builder = [[SDDSchedulerBuilder alloc] initWithNamespace:@""];
    SDDScheduler* scheduler = [builder schedulerWithContext:self
                                                 eventsPool:epool
                                                        dsl:dsl
                                                      queue:[SDDDirectExecutionQueue new]
                               ];
    
    [scheduler startWithEventsPool:epool];
    
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

- (BOOL)yes { return YES; }
- (BOOL)no  { return NO;  }

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


//- (void)testDriveWithArgumentedMethod {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//      [s2 e: o2]
//     
//     [s1]->[s2]: EventWithArgument (@flagValueIsEqualWithArgument)
//     );
//    
//    NSMutableArray* flows = [NSMutableArray array];
//    self.flagValue = @100;
//    SDDEventsPool* pachine = [[SDDMachineBuilder new] machineWithContext:self
//                                                                DSL:dsl
//                                                           routines:@{
//                                                                      @"o2": ^(id _) { [flows addObject:@"2"]; }
//                                                                      }
//                                                         conditions:nil];
//    
//    [machine run];
//    [machine scheduleEvent:@"EventWithArgument" argument:@(100)];
//    
//    XCTAssertEqualObjects([flows componentsJoinedByString:@""], @"2");
//}

//- (void)testPerformingActionWhenTransited {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//      [s2 e:]
//     
//     [s1]->[s2]: ActionEvent / @mdownEventAction
//     );
//
//    [self performTestWithDSL:dsl expectedFlows:@"EAction" customActions:^(SDDEventsPool* pachine) {
//        [machine scheduleEvent:@"ActionEvent"];
//    }];
//}
//
//- (void)testPerformPostActionCombinedWithPositiveCondition {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: ActionEvent (@shouldGo) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"EAction" customActions:^(SDDEventsPool* pachine) {
//        [machine scheduleEvent:@"ActionEvent"];
//    }];
//}
//
//- (void)testPerformPostActionCombinedWithNegativeCondition {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: ActionEvent (@shouldNotGo) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"" customActions:^(SDDEventsPool* pachine) {
//        [machine scheduleEvent:@"ActionEvent"];
//    }];
//}
//
//- (void)mdownArgument:(NSString*)arg {
//    [self.currentFlows addObject:arg];
//}
//
//- (void)testPostActionWithArgument {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: ActionEvent / @mdownArgument
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"U1ik22" customActions:^(SDDEventsPool* pachine) {
//        [machine scheduleEvent:@"ActionEvent" argument:@"U1ik22"];
//    }];
//}
//
//- (void)testArgumentConditionIsYES {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//      [s2 e:]
//     
//     [s1]->[s2]: Event (arg.shouldyes) / @mdownEventAction
//    );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"EAction" customActions:^(SDDMachine *m) {
//        SDDTestMockArgument* argument = [[SDDTestMockArgument alloc] init];
//        argument.shouldyes = YES;
//        [m scheduleEvent:@"Event" argument:argument];
//    }];
//}
//
//- (void)testArgumentConditionIsNO {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: Event (arg.shouldyes) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"" customActions:^(SDDMachine *m) {
//        SDDTestMockArgument* argument = [[SDDTestMockArgument alloc] init];
//        argument.shouldyes = NO;
//        [m scheduleEvent:@"Event" argument:argument];
//    }];
//}
//
//- (void)testConditionWithNegateForYES {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: Event (!@shouldGo) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"" customActions:^(SDDMachine *m) {
//        [m scheduleEvent:@"Event"];
//    }];
//}
//
//- (void)testConditionWithNegateForNO {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: Event (!@shouldNotGo) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"EAction" customActions:^(SDDMachine *m) {
//        [m scheduleEvent:@"Event"];
//    }];
//}
//
//- (void)testArgumentConditionWithNegateForYES {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: Event (!arg.shouldyes) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"" customActions:^(SDDMachine *m) {
//        SDDTestMockArgument* argument = [[SDDTestMockArgument alloc] init];
//        argument.shouldyes = YES;
//        [m scheduleEvent:@"Event" argument:argument];
//    }];
//}
//
//- (void)testArgumentConditionWithNegateForNO {
//    NSString* const dsl = SDDOCLanguage
//    (
//     ~[s1 e:]
//     [s2 e:]
//     
//     [s1]->[s2]: Event (!arg.shouldyes) / @mdownEventAction
//     );
//    
//    [self performTestWithDSL:dsl expectedFlows:@"EAction" customActions:^(SDDMachine *m) {
//        SDDTestMockArgument* argument = [[SDDTestMockArgument alloc] init];
//        argument.shouldyes = NO;
//        [m scheduleEvent:@"Event" argument:argument];
//    }];
//}
//
@end
