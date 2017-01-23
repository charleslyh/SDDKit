//
//  LoginViewController.m
//  SDDExamples
//
//  Created by Tom Zhang on 16/5/18.
//  Copyright © 2016年 CharlesLee All rights reserved.
//

#import "SDDELoginViewController.h"
#import <SDDKit/SDDKit.h>

static NSString* const kLVCMockVerifyPhoneNumber    = @"12345678901";
static NSString* const kLVCMockVerifySMSCode        = @"654321";
static NSInteger const kLVCMockVerifyClue           = 88888888;

@interface UIColor (LVCDisableColor)
+ (UIColor*)LVCButtonDisableColor;
+ (UIColor*)LVCButtonOrangeColor;
@end

@implementation UIColor (LVCDisableColor)
+ (UIColor*)LVCButtonDisableColor {
    return [UIColor colorWithRed:1.0/3.0 green:1.0/3.0 blue:1.0/3.0 alpha:0.5];
}

+ (UIColor*)LVCButtonOrangeColor {
    return [UIColor colorWithRed:1.0 green:180.0/255.0 blue:0 alpha:1.0];
}
@end

@interface LoginViewController()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIView   *grayMaskView;
@property (nonatomic, weak) IBOutlet UIView   *grayMaskView2;
@property (nonatomic, weak) IBOutlet UILabel  *failureTip;
@property (nonatomic, weak) IBOutlet UIButton *SMSCodeRequestingButton;
@property (nonatomic, weak) IBOutlet UIButton *verifyButton;
@property (nonatomic, weak) IBOutlet UITextField *phoneNumberField;
@property (nonatomic, weak) IBOutlet UITextField *SMSCodeField;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation LoginViewController {
    SDDBuilder *_hsms;
}

-(void)disableSMSButton {
    self.SMSCodeRequestingButton.enabled = NO;
    self.SMSCodeRequestingButton.backgroundColor = [UIColor LVCButtonDisableColor];
}

-(void)enableSMSButton {
    self.SMSCodeRequestingButton.enabled = YES;
    self.SMSCodeRequestingButton.backgroundColor = [UIColor blueColor];
}

-(void)restoreSMSButtonTitle {
    [self.SMSCodeRequestingButton setTitle:@"获取验证码" forState:UIControlStateNormal];
}

-(void)startCountDown {
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int remainingSeconds = 10;
        while (wself && remainingSeconds > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [wself.SMSCodeRequestingButton setTitle:[NSString stringWithFormat:@"%d秒后重试", remainingSeconds]
                                               forState:UIControlStateNormal];
            });
            
            remainingSeconds -= 1;
            sleep(1);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(TimesUp)];
        });
    });
}

-(void)requestSMSCode {
    // Do Something.
}

-(BOOL)isPhoneNumber {
    static NSPredicate* predicate;
    if (!predicate) {
        predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES \"^1\\\\d{10}\""];
    }
    return [predicate evaluateWithObject:self.phoneNumberField.text];
}

-(void)enablePhoneNumberField {
    self.phoneNumberField.enabled = YES;
    self.grayMaskView.hidden = YES;
}

-(void)disablePhoneNumberField {
    self.phoneNumberField.enabled = NO;
    self.grayMaskView.hidden = NO;
}

-(void)enableSMSCodeField {
    self.SMSCodeField.enabled = YES;
    self.grayMaskView2.hidden = YES;
}

-(void)disableSMSCodeField {
    self.SMSCodeField.enabled = NO;
    self.grayMaskView2.hidden = NO;
}

-(void)resetSMSCodeField {
    self.SMSCodeField.text = @"";
}

-(void)focusOnSMSCodeField {
    [self.SMSCodeField becomeFirstResponder];
}

-(BOOL)isValidCode {
    static NSPredicate* predicate;
    if (!predicate) {
        predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES \"^\\\\d{6}\""];
    }
    return [predicate evaluateWithObject:self.SMSCodeField.text];
}

-(BOOL)isValidInput {
    return [self isPhoneNumber] && [self isValidCode];
}

-(void)disableVerifyButton {
    self.verifyButton.enabled = NO;
    self.verifyButton.backgroundColor = [UIColor LVCButtonDisableColor];
}

-(void)enableVerifyButton {
    self.verifyButton.enabled = YES;
    self.verifyButton.backgroundColor = [UIColor LVCButtonOrangeColor];
}

-(void)performMockLogin {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSNumber *verify;
        
        BOOL correctPhoneNumber = [self.phoneNumberField.text isEqualToString:kLVCMockVerifyPhoneNumber];
        BOOL correctSMSCode     = [self.SMSCodeField.text isEqualToString:kLVCMockVerifySMSCode];
        if (correctPhoneNumber && correctSMSCode) {
            verify = @(kLVCMockVerifyClue);
        }
        [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral2(DoneVerifying, verify)];
    });
}

-(void)performLogin {
    [self performMockLogin];
}

-(BOOL)isLoginSucceed:(SDDELiteralEvent *)e {
    NSNumber *number = e.param;
    return [number integerValue] == kLVCMockVerifyClue;
}

-(void)handleLoginSuccess {
    self.successHandler();
}

-(void)hideActivityIndicator {
    [self.indicator stopAnimating];
}

-(void)showActivityIndicator {
    [self.indicator startAnimating];
}

-(void)hideFailureTip {
    [UIView animateWithDuration:0.25 animations:^{
        self.failureTip.alpha = 0.0;
    }];
}

-(void)showFailureTip {
    [UIView animateWithDuration:0.25 animations:^{
        self.failureTip.alpha = 1.0;
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(DoneFailureToasting)];
    });
}

-(void)setupSMSButtonState {
    [_hsms addStateMachineWithContext:self dsl:SDDOCLanguage
     ([SMSButton
         [Disabled e:disableSMSButton]
         [Normal   e:enableSMSButton]
         [CountDown
            e:disableSMSButton startCountDown requestSMSCode
            x:restoreSMSButtonTitle
         ]
      ]
      
      [.] -> [Disabled]: $Initial
      
      [Disabled]  -> [Normal]:    DidChangeTextFields(isPhoneNumber)
      [Normal]    -> [Disabled]:  DidChangeTextFields(!isPhoneNumber)
      [Normal]    -> [CountDown]: DidTouchSMSCodeButton
      [CountDown] -> [Normal]:    TimesUp(isPhoneNumber)
      [CountDown] -> [Disabled]:  TimesUp(!isPhoneNumber)
     )];
}

-(void)setupPhoneNumberFieldState {
    [_hsms addStateMachineWithContext:self dsl:SDDOCLanguage
     ([PhoneNumberField
         [Normal    e:enablePhoneNumberField]
         [Disabled  e:disablePhoneNumberField]
      ]
      
      [.] -> [Normal]:   $Initial
      
      [Normal]   -> [Disabled]: DidTouchSMSCodeButton
      [Disabled] -> [Normal]:   TimesUp
      )];
}

-(void)setupSMSCodeFieldState {
    [_hsms addStateMachineWithContext:self dsl:SDDOCLanguage
     ([SMSCodeField
         [Disabled e:disableSMSCodeField resetSMSCodeField]
         [Normal   e:enableSMSCodeField  resetSMSCodeField]
       ]
      
      [.] -> [Normal]: $Initial
      
      [Disabled] -> [Normal]:   DidTouchSMSCodeButton / focusOnSMSCodeField
      [Normal]   -> [Disabled]: DidChangePhoneNumber
      )];
}

-(void)setupVerifyButtonState {
    [_hsms addStateMachineWithContext:self dsl:SDDOCLanguage
     ( [VerifyButton
          [Disabled  e:disableVerifyButton]
          [Normal    e:enableVerifyButton]
          [Verifying e:disableVerifyButton dismissKeyboard]
          [Success   e:disableVerifyButton handleLoginSuccess]
        ]
      
      [.] -> [Disabled]: $Initial
      
      [Disabled]  -> [Normal]:    DidChangeTextFields(isValidInput)
      [Normal]    -> [Disabled]:  DidChangeTextFields(!isValidInput)
      [Normal]    -> [Verifying]: DidTouchVerifyButton/performLogin
      [Verifying] -> [Normal]:    DoneVerifying(!isLoginSucceed)
      [Verifying] -> [Success]:   DoneVerifying(isLoginSucceed)
      )];
}

-(void)setupActivityIndicatorState {
    NSString* dsl = SDDOCLanguage
    ( [ActivityIndicator
        [Hidden    e:hideActivityIndicator]
        [Shown     e:showActivityIndicator]
       ]
     
     [.] -> [Hidden]: $Initial
     
     [Hidden] -> [Shown]:  DidTouchVerifyButton
     [Shown]  -> [Hidden]: DoneVerifying
    );
    
    [_hsms addStateMachineWithContext:self dsl:dsl];
}

-(void)setupFailureTipState {
    NSString* dsl = SDDOCLanguage
    ( [FailureTip
         [Hidden]
         [Shown
            e: showFailureTip
            x: hideFailureTip
         ]
      ]
     
     [.] -> [Hidden]: $Initial
     
     [Hidden] -> [Shown]:  DoneVerifying(!isLoginSucceed)
     [Shown]  -> [Hidden]: DoneFailureToasting
     );
    
    [_hsms addStateMachineWithContext:self dsl:dsl];
}

-(void)setupDomainWidgets {
    _hsms = [[SDDBuilder alloc] initWithLogger:[SDDConsoleLogger defaultLogger]
                                         epool:[SDDEventsPool sharedPool]];
    
    [self setupSMSButtonState];
    [self setupPhoneNumberFieldState];
    [self setupSMSCodeFieldState];
    [self setupVerifyButtonState];
    [self setupActivityIndicatorState];
    [self setupFailureTipState];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // 让键盘随着界面一起出现
    [self.phoneNumberField becomeFirstResponder];
    
    [self setupDomainWidgets];
}

- (IBAction)phoneNumberTextDidChange:(UITextField *)sender {
    [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(DidChangeTextFields)];
    [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(DidChangePhoneNumber)];
}

- (IBAction)SMSCodeTextDidChange:(UITextField *)sender {
    [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(DidChangeTextFields)];
}

- (IBAction)didTouchSMSButton:(id)sender {
    [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(DidTouchSMSCodeButton)];
}

- (IBAction)didTouchStopButton:(id)sender {
    self.closingHandler();
}

- (IBAction)didTouchVerifyButton:(id)sender {
    [[SDDEventsPool sharedPool] scheduleEvent:SDDELiteral(DidTouchVerifyButton)];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)dismissKeyboard {
    [self.view endEditing:YES];
}
@end
