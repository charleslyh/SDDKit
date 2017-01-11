//
//  SDDEStringMatchingViewController.m
//  SDDExamples
//
//  Created by zhangji on 5/26/16.
//  Copyright © 2016 yy. All rights reserved.
//

#import "SDDEStringMatchingViewController.h"
#import "SDDEContext.h"

#import <SDDKit/SDDKit.h>

@interface SDDEStringMatchingViewController ()
{
    SDDBuilder *_sddBuilder;
    
    __weak IBOutlet UITextField *originTxtField;
    __weak IBOutlet UITextField *patternTxtField;
}

@end

@implementation SDDEStringMatchingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSDDBuilder];
}

- (void)setupSDD
{
    NSArray *stateTable = [self createStateTable:patternTxtField.text];
    [self setupMatchState:stateTable];
}

#pragma mark - SDDBuilder

- (void)setupSDDBuilder {
    _sddBuilder = [[SDDBuilder alloc] initWithLogger:nil epool:[SDDEventsPool sharedPool]];
}

#pragma mark - MatchState

- (void)setupMatchState:(NSArray *)stateTable
{
    NSString *dsl = @"";
    dsl = [dsl stringByAppendingString:[self declareMultiState:stateTable]];
    dsl = [dsl stringByAppendingString:[self initializeMultiStateTransmit:stateTable]];

    [_sddBuilder addStateMachineWithContext:self dsl:dsl];

}

#pragma mark - ConstructDSL

- (NSString *)declareMultiState:(NSArray *)stateTable
{
    NSString *declareDSL = @"";
    //head
    declareDSL = [declareDSL stringByAppendingString:[NSString stringWithFormat:@"[Match"]];
    //start state
    declareDSL = [declareDSL stringByAppendingString:[NSString stringWithFormat:@" ~[step_0]"]];
    //other state
    for (int i = 0; i < [stateTable count]; i++) {
        declareDSL = [declareDSL stringByAppendingString:[NSString stringWithFormat:@"[step_%d]", i]];
    }
    //end
    declareDSL = [declareDSL stringByAppendingString:[NSString stringWithFormat:@"]"]];
    
    return declareDSL;
}

- (NSString *)initializeMultiStateTransmit:(NSArray *)stateTable
{
    NSString *stateTransmitDSL = @"";
    
    for (int i = 0; i < [stateTable count] - 1; i++) {
        NSArray *cArr = [stateTable objectAtIndex:i];
        for (int j = 0; j < [cArr count]; j++) {
            NSString *str = [NSString stringWithFormat:@"%c", j+97];
            int nextState = [((NSNumber *)[cArr objectAtIndex:j]) intValue];
            stateTransmitDSL = [stateTransmitDSL stringByAppendingString:[NSString stringWithFormat:@"[step_%d] -> [step_%d] : %@", i, nextState, str]];
        }
    }
    
    return stateTransmitDSL;
}

#pragma mark - CreateStateTable
- (NSArray *)createStateTable:(NSString *)pattern
{
    NSMutableArray *stateTable = [[NSMutableArray alloc] init];
    NSInteger len = [pattern length];
    for (NSInteger state = 0;state <= len;state++) {
        NSMutableArray *cArr = [[NSMutableArray alloc] init];
        [stateTable addObject:cArr];
        for (int c = 97; c <= 122; c++) {
            NSString *curChar = [NSString stringWithFormat:@"%c", c];
            NSNumber *nextState = [self getNextStateWithPattern:pattern curState:state curChar:curChar];
            [cArr addObject:nextState];
        }
    }
    
    return stateTable;
}

- (NSNumber *)getNextStateWithPattern:(NSString *)pattern
                             curState:(NSInteger)curState
                                 curChar:(NSString *)curChar
{
    if (curState == [pattern length]) {
        return @(0);
    }
    NSString *charInPattern = [pattern substringWithRange:NSMakeRange(curState, 1)];
    if (curState < [pattern length] && [curChar isEqualToString:charInPattern])
        return @(curState+1);
    
    NSInteger ns, i;
    for (ns = curState; ns > 0; ns--)
    {
        if([[pattern substringWithRange:NSMakeRange(ns - 1, 1)] isEqualToString:curChar])
        {
            for(i = 0; i < ns-1; i++)
            {
                NSString *prefix = [pattern substringWithRange:NSMakeRange(i, 1)];
                NSString *suffix = [pattern substringWithRange:NSMakeRange(curState - ns + 1 + i, 1)];
                if (![prefix isEqualToString:suffix])
                    break;
            }
            if (i == ns-1)
                return @(ns);
        }
    }
    
    return @(0);
}

#pragma mark - Action
- (IBAction)onClickStartSearch:(id)sender {
    
    [self setupSDD];
    
    for (int index = 0; index < [originTxtField.text length]; index++) {
        NSString *subStr = [originTxtField.text substringWithRange:NSMakeRange(index, 1)];
        [_sddBuilder.epool scheduleEvent:subStr];
    }
}

@end
