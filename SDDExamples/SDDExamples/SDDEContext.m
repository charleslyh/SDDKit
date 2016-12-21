//
//  Context.m
//  SDDExamples
//
//  Created by Tom Zhang on 16/5/19.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "SDDEContext.h"

#import <SDDKit/SDDKit.h>
#import <UIKit/UIKit.h>


@implementation NSString (Test)

- (BOOL)isValid    { return NO; }
- (BOOL)isNotEmpty { return NO; }

@end


Context* globalContext;

@interface Context()
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic) UITextField *usernameField;
@property (nonatomic) UITextField *passwordField;
@end

@implementation Context

- (void)enableSMSButton {}
- (void)enableVerifyButton {}
- (void)loginWithCompletion:(void (^)(BOOL, BOOL))completion {}
- (void)showPicCodeInputControls {}
- (void)showMessage:(NSString *)message {}
- (void)dismiss {}
- (BOOL)isMessageAlreadyShown { return NO; }

- (IBAction)didTouchLoginButton:(id)sender {
    if ([self.usernameField.text isValid] && [self.passwordField.text isNotEmpty]) {
        self.usernameField.enabled = NO;
        self.passwordField.enabled = NO;
        
        [self loginWithCompletion:^(BOOL authorized, BOOL needPicCodeVerify) {
            if (authorized) {
                if (![self isMessageAlreadyShown]) {
                    [self showMessage:@"登录成功"];
                }
                
                [self dismiss];
            } else {
                if (needPicCodeVerify) {
                    if (![self isMessageAlreadyShown]) {
                        [self showMessage:@"请进行进一步验证"];
                    }
                    [self showPicCodeInputControls];
                } else {
                    if (![self isMessageAlreadyShown]) {
                        [self showMessage:@"用户名或密码错误"];
                    }
                }
            }
            
            self.usernameField.enabled = YES;
            self.passwordField.enabled = YES;
        }];
    }
}

@end
