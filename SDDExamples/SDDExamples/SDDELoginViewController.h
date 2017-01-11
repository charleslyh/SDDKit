//
//  LoginViewController.h
//  SDDExamples
//
//  Created by Tom Zhang on 16/5/18.
//  Copyright © 2016年 CharlesLee All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (nonatomic, copy) void (^closingHandler)();
@property (nonatomic, copy) void (^successHandler)();
@end
