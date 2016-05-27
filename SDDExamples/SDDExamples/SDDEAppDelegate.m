//
//  AppDelegate.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <SDDI/SDDI.h>
#import "SDDEAppDelegate.h"
#import "SDDEContext.h"

@implementation SDDEAppDelegate

- (void)setupGlobalContext {
    SDDISocketReporter* reporter = [[SDDISocketReporter alloc] initWithHost:@"localhost" port:9800];
    [reporter start];
    
    globalContext = [[Context alloc] initWithReporter:reporter];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupGlobalContext];
    
    return YES;
}

@end
