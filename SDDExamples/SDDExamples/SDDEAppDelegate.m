//
//  AppDelegate.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 CharlesLee All rights reserved.
//

#import "SDDEAppDelegate.h"
#import "SDDEContext.h"

@implementation SDDEAppDelegate

- (void)setupGlobalContext {
    globalContext = [[Context alloc] init];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupGlobalContext];
    
    return YES;
}

@end
