//
//  ViewController.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "ViewController.h"
#import <SDDI/SDDI.h>


@interface ViewController ()
@end

@implementation ViewController {
    SDDEventsPool *_epool;
    SDDScheduler *_scheduler;
    SDDISocketReporter *_reporter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _reporter = [[SDDISocketReporter alloc] initWithHost:@"172.19.143.199" port:9800];
    [_reporter start];
    
    NSString* dsl = SDDOCLanguage
    (
     [E ~[D]
      [B]
      [D ~[A] [A][C]]
      ]
     
     [B]->[A]: E1
     [D]->[B]: E2
     [A]->[C]: E3
     [B]->[C]: E4
     );
    
    _epool = [SDDEventsPool defaultPool];
    SDDSchedulerBuilder *builder = [[SDDSchedulerBuilder alloc] initWithNamespace:@"" logger:_reporter];
    _scheduler = [builder schedulerWithContext:self dsl:dsl queue:[NSOperationQueue mainQueue]];
    
    [_scheduler startWithEventsPool:_epool];
}

- (IBAction)didTouchButton:(UIButton *)sender {
    NSArray *allEvents = @[@"E1", @"E2", @"E3", @"E4"];
    [_epool scheduleEvent:allEvents[sender.tag - 10]];
}

@end
