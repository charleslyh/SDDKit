//
//  location-relateServiceViewController.m
//  SDDExamples
//
//  Created by siyuxing on 16/5/20.
//  Copyright © 2016年 yy. All rights reserved.
//

#import "SDDELBSServiceViewController.h"
#import "SDDEContext.h"

#import <SDDKit/SDDKit.h>
#import <CoreLocation/CoreLocation.h>

@interface SDDELBServiceViewController ()<CLLocationManagerDelegate>
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *locationUpdateIndicatorView;
@property (nonatomic, weak) IBOutlet UILabel *locationContentLabel;
@property (nonatomic, weak) IBOutlet UISwitch *locationServiceSwitch;
@property (nonatomic) SDDSchedulerBuilder * sddBuilder;
@property (nonatomic) CLLocationManager *locationManager;
@end

@implementation SDDELBServiceViewController

- (void) setupSDDBuilder {
    _sddBuilder = [[SDDSchedulerBuilder alloc] initWithNamespace:@"LocationRelateService"
                                                          logger:[[SDDSchedulerConsoleLogger alloc] initWithMasks:SDDSchedulerLogMaskAll]
                                                           queue:[NSOperationQueue currentQueue]];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    [self setupSDDBuilder];
    [self setupLocationService];
    [self setupIndicatorView];
    [self setupMessageState];
    [self setupLBSSwitchState];
    
    [_sddBuilder.epool scheduleEvent:@"UIViewDidLoad"];
}

#pragma mark - Widget: IndicatorView

- (void) stopUpdatingAnimation {
    [self.locationUpdateIndicatorView stopAnimating];
}

- (void) startUpdatingAnimation {
    [self.locationUpdateIndicatorView startAnimating];
}

- (void) setupIndicatorView {
    [self.sddBuilder hostSchedulerWithContext:self dsl:SDDOCLanguage
     ([Indicator ~[Hidden]
       [Hidden    e:stopUpdatingAnimation]
       [Animating e:startUpdatingAnimation]
       ]
      
      [Hidden] -> [Animating] : LBSWillStartUpdatingLocation
      [Animating] -> [Hidden] : LBSDidUpdateLocation
      [Animating] -> [Hidden] : LBSFailedUpdateLocation
      )];
}

#pragma mark - Widget: contentLabel

- (void) showStartingMessage {
    self.locationContentLabel.text = @"没有收到任何地理位置";
}

- (void) showLocationMessage:(CLLocation *)location {
    NSAssert([location isKindOfClass:[CLLocation class]], @"这里应该使用NSAssert进行断言");

    NSString *labelContent = [NSString stringWithFormat:@"经度:%@，纬度:%@",@(location.coordinate.latitude),@(location.coordinate.longitude)];
    self.locationContentLabel.text = labelContent;
}

- (void) showLBSErrorMessage {
    self.locationContentLabel.text = @"LBS服务出现错误";
}

- (void) setupMessageState {
    [self.sddBuilder hostSchedulerWithContext:self dsl:SDDOCLanguage
     ([Message]
      
      [Message] -> [Message]: UIViewDidLoad           / showStartingMessage
      [Message] -> [Message]: LBSDidUpdateLocation    / showLocationMessage
      [Message] -> [Message]: LBSFailedUpdateLocation / showLBSErrorMessage
      )];
}

#pragma mark - Widget: LBSSwitch

- (void) enableLBSSwitch  { self.locationServiceSwitch.enabled = YES; }
- (void) disableLBSSwitch { self.locationServiceSwitch.enabled = NO;  }
- (void) turnOffLBSSwitch { self.locationServiceSwitch.on = NO; }
- (BOOL) isSwitchOn       { return self.locationServiceSwitch.on; }

- (IBAction)didToggleLocationServiceSwitch:(UISwitch *)switchCtrl {
    [_sddBuilder.epool scheduleEvent:switchCtrl.on ? @"UIDidTurnOnLBSSwitch" : @"UIDidTurnOffLBSSwitch"];
}

- (void) setupLBSSwitchState {
    NSString *dsl = SDDOCLanguage
    ([Switch ~[Disabled]
      [Disabled e:disableLBSSwitch turnOffLBSSwitch]
      [Enabled e:enableLBSSwitch]
      ]
     
     [Switch] -> [Disabled]: UIViewDidLoad (!isLBSAvailable)
     [Switch] -> [Enabled]:  UIViewDidLoad (isLBSAvailable)
     [Switch] -> [Disabled]: LBSDidChangeAuthorization(!isLBSAvailable)
     [Switch] -> [Enabled]:  LBSDidChangeAuthorization(isLBSAvailable)
     );
    
    [_sddBuilder hostSchedulerWithContext:self dsl:dsl];
    
    

}

#pragma mark - Widget: Location Manager

- (BOOL) isLBSNotDetermined {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusNotDetermined;
}

- (BOOL) isLBSAvailable {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways;
}

- (void) setupLocationManager {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void) requestAuthorization {
    [self.locationManager requestAlwaysAuthorization];
}

- (void) startUpdatingLocation {
    [_sddBuilder.epool scheduleEvent:@"LBSWillStartUpdatingLocation"];
    [self.locationManager startUpdatingLocation];
}

- (void) stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [_sddBuilder.epool scheduleEvent:@"LBSDidChangeAuthorization"];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [_sddBuilder.epool scheduleEvent:@"LBSDidUpdateLocation" withParam:locations.firstObject];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [_sddBuilder.epool scheduleEvent:@"LBSFailedUpdateLocation"];
}

- (void) countdownForNextUpdate {
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wself.sddBuilder.epool scheduleEvent:@"LBSDidFinishFrozenCountdown"];
    });
}

- (void) setupLocationService {
    [self.sddBuilder hostSchedulerWithContext:self dsl:SDDOCLanguage
     ([LBService e:setupLocationManager ~[Disabled]
       [Disabled]
       [Enabled
        [On
         [Update e:startUpdatingLocation x:stopUpdatingLocation]
         [Frozen e:countdownForNextUpdate]
         ]
        [Off]
        ]
       ]
      
      // 初始加载时，需要进行LBS服务验权
      [Disabled] -> [Disabled]: UIViewDidLoad(isLBSNotDetermined) / requestAuthorization
      
      // 如果初始加载时发现已具备LBS访问权限，则可以直接进行地点更新
      [Disabled] -> [Update]:   UIViewDidLoad(!isLBSNotDetermined & isSwitchOn)
      [Disabled] -> [Off]:      UIViewDidLoad(!isLBSNotDetermined & !isSwitchOn)
      [Disabled] -> [Update]:   LBSDidChangeAuthorization(isLBSAvailable & isSwitchOn)
      [Disabled] -> [Off]:      LBSDidChangeAuthorization(isLBSAvailable & !isSwitchOn)
      
      // 如果用户的速度足够快，或者地点更新速度足够慢……则可能在更新过程中，用户关闭了LBS授权
      [Enabled] ->  [Disabled]: LBSDidChangeAuthorization(!isLBSAvailable)
      
      // 成功获取地点更新后，需要等待一段时间再获取下一次更新，避免频繁的位置更新消耗系统资源
      [Update] -> [Frozen]: LBSDidUpdateLocation
      [Frozen] -> [Update]: LBSDidFinishFrozenCountdown
      
      // 无论是正在更新，还是在等待下一次更新，只要用户关闭了更新行为，则都应该停止地点获取
      [On]  -> [Off]:    UIDidTurnOffLBSSwitch
      
      // 和上面不同，如果用户开启了地点获取服务，则应该直接进入Update状态
      [Off] -> [Update]: UIDidTurnOnLBSSwitch
      )];
}

@end
