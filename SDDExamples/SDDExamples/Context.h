//
//  Context.h
//  SDDExamples
//
//  Created by Tom Zhang on 16/5/19.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SDDISocketReporter;

@interface Context : NSObject
@property (nonatomic) SDDISocketReporter* reporter;
- (instancetype)initWithReporter:(SDDISocketReporter*)reporter;
@end

extern Context* globalContext;