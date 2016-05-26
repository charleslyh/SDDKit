//
//  SDDEStringMatchingViewController.m
//  SDDExamples
//
//  Created by zhangji on 5/26/16.
//  Copyright © 2016 yy. All rights reserved.
//

#import "SDDEStringMatchingViewController.h"
#import "SDDI.h"
#import "SDDEContext.h"

@interface SDDEStringMatchingViewController ()
{
    SDDSchedulerBuilder *_sddBuilder;
    
    NSString *_originString;
    NSString *_pattern;
}

@end

@implementation SDDEStringMatchingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _originString = @"abcbababacacbab";
//    _originString = @"abcbababaabcbab";
    _pattern = @"ababaca";

    
    [self setupSDDBuilder];
    [self setupMatchState];
}

#pragma mark - SDDBuilder

- (void)setupSDDBuilder {
    _sddBuilder = [[SDDSchedulerBuilder alloc] initWithNamespace:@"StringMatching"
                                                          logger:globalContext.reporter
                                                           queue:[NSOperationQueue currentQueue]];
    
    [globalContext.reporter setScreenshotForTransitionEnabled:NO];
}

#pragma mark - MatchState

- (void)setupMatchState
{
    
    //ababaca
    NSString* dsl = SDDOCLanguage
    (
     [Match ~[step0_]
      [step0_]
      [step1_a]
      [step2_b]
      [step3_a]
      [step4_b]
      [step5_a]
      [step6_c]
      [step7_a]
      ]
     
     [step0_]     ->  [step1_a]:    a
     [step0_]     ->  [step0_]:    b
     [step0_]     ->  [step0_]:    c
     
     [step1_a]     ->  [step1_a]:    a
     [step1_a]     ->  [step2_b]:    b
     [step1_a]     ->  [step0_]:    c
     
     [step2_b]     ->  [step3_a]:    a
     [step2_b]     ->  [step0_]:    b
     [step2_b]     ->  [step0_]:    c
     
     [step3_a]     ->  [step1_a]:    a
     [step3_a]     ->  [step4_b]:    b
     [step3_a]     ->  [step0_]:    c
     
     [step4_b]     ->  [step5_a]:    a
     [step4_b]     ->  [step0_]:    b
     [step4_b]     ->  [step0_]:    c
     
     [step5_a]     ->  [step1_a]:    a
     [step5_a]     ->  [step4_b]:    b
     [step5_a]     ->  [step6_c]:    c
     
     [step6_c]     ->  [step7_a]:    a
     [step6_c]     ->  [step0_]:    b
     [step6_c]     ->  [step0_]:    c

     );

    [_sddBuilder hostSchedulerWithContext:self dsl:dsl];

}

#pragma mark - Action
- (IBAction)onClickStartSearch:(id)sender {
    
    for (int index = 0; index < [_originString length]; index++) {
        NSString *subStr = [_originString substringWithRange:NSMakeRange(index, 1)];
        [_sddBuilder.epool scheduleEvent:subStr];
    }
}

@end
