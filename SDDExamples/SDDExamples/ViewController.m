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
    SDDScheduler *_simple;
    SDDScheduler *_verbose;
    
    SDDISocketReporter *_reporter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _reporter = [[SDDISocketReporter alloc] initWithHost:@"localhost" port:9800];
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
    
    SDDSchedulerBuilder *builder = [[SDDSchedulerBuilder alloc] initWithNamespace:nil logger:_reporter queue:[NSOperationQueue currentQueue]];

    _simple = [builder schedulerWithContext:self dsl:dsl];
    [_simple startWithEventsPool:[SDDEventsPool defaultPool]];
    
    NSString *verboseDSL = SDDOCLanguage
    (
     [Guide ~[Await]
      [Await]
      [Present]
      [Done]
      ]
     
     [Await]   -> [Present]: UIViewDidLoad(isFirstLaunch)
     [Await]   -> [Done]:    UIViewDidLoad(!isFirstLaunch)
     
     [Present] -> [Done]:    DidAskToCloseGuideVC
    );
    
    _verbose = [builder schedulerWithContext:self dsl:verboseDSL];
    [_verbose startWithEventsPool:[SDDEventsPool defaultPool]];
    
    [[SDDEventsPool defaultPool] scheduleEvent:@"UIViewDidLoad"];
}

- (BOOL)isFirstLaunch {
    return NO;
}

- (IBAction)didTouchButton:(UIButton *)sender {
    NSArray *allEvents = @[@"E1", @"E2", @"E3", @"E4"];
    [[SDDEventsPool defaultPool] scheduleEvent:allEvents[sender.tag - 10]];
}

@end
