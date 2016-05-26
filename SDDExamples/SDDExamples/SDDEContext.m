//
//  Context.m
//  SDDExamples
//
//  Created by Tom Zhang on 16/5/19.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "SDDEContext.h"
#import <SDDI/SDDI.h>

Context* globalContext;

@implementation Context
-(instancetype)initWithReporter:(SDDISocketReporter *)reporter {
    if (self = [super init]) {
        _reporter = reporter;
    }
    return self;
}
@end
