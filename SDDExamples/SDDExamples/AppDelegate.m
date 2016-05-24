//
//  AppDelegate.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <SDDI/SDDI.h>
#import "AppDelegate.h"
#import "Context.h"

@implementation AppDelegate

- (void)setupGlobalContext {
    SDDISocketReporter* reporter = [[SDDISocketReporter alloc] initWithHost:@"172.19.144.123" port:9800];
    [reporter start];
    
    globalContext = [[Context alloc] initWithReporter:reporter];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupGlobalContext];
    
    return YES;
}

@end
