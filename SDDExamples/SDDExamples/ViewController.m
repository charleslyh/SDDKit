//
//  ViewController.m
//  SDDExamples
//
//  Created by 黎玉华 on 16/2/1.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "ViewController.h"
#import "LoginViewController.h"

@implementation ViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToLoginVC"]) {
        LoginViewController* vc = segue.destinationViewController.childViewControllers.firstObject;
        
        void (^dismiss)() = ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        
        vc.successHandler = vc.closingHandler = dismiss;
    }
}
@end
