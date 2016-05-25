//
//  location-relateServiceViewController.m
//  SDDExamples
//
//  Created by siyuxing on 16/5/20.
//  Copyright © 2016年 yy. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "location-relateServiceViewController.h"
#import "SDDI.h"
#import "Context.h"


static NSString * const kLRServiceEventUpdateFailed = @"LocationServiceFailed";
static NSString * const kLRServiceEventUpdating = @"LocationServiceUpdating";
static NSString * const kLRServiceEventFree = @"LocationServiceFree";
static NSString * const kLRServiceEventClose = @"LocatonServiceClose";
static NSString * const kLRServiceEventOpen = @"LocatonServiceOpen";


static NSString * const kCLAuthorizationStatusAuthorizationChanged = @"LocationServiceAuthorizationChanged";
static NSString * const kLRServiceEventAuthorizationDenied = @"LocationServiceDenied";
static NSString * const kLRServiceEventAuthorizationNotDetermined = @"LocationServiceNotDetermined";
static NSString * const kLRServiceEventAuthorizationAlways = @"LocationServiceAlways";
static NSString * const kLRServiceEventAuthorizationWhenInUse = @"LocationServiceWhenInUse";
static NSString * const KLRServiceEventAuthorizationEnabled = @"LocationServiceEnabled";
static NSString * const KLRServiceEventAuthorizationDisabled = @"LocationServiceDisabled";


@interface location_relateServiceViewController ()<CLLocationManagerDelegate>

@property (strong,nonatomic)  SDDSchedulerBuilder * sddBuilder;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *locationUpdateIndicatorView;

@property (weak, nonatomic) IBOutlet UILabel *locationContentLabel;

@property (nonatomic,strong) CLLocationManager *locationManager;

@property (weak, nonatomic) IBOutlet UISwitch *locationServiceSwitch;

@end

@implementation location_relateServiceViewController


- (void) viewDidLoad
{
    [super viewDidLoad];
    [self configLocationManagerSDD];
}


- (void) dealloc
{
    [_sddBuilder.epool removeSubscriber:globalContext.reporter];
}

- (SDDSchedulerBuilder *) sddBuilder
{
    if (!_sddBuilder) {
        _sddBuilder = [[SDDSchedulerBuilder alloc] initWithNamespace:@"LocationRelateService"
                                                                             logger:globalContext.reporter
                                                                              queue:[NSOperationQueue currentQueue]
                                                                         ];
        [_sddBuilder.epool addSubscriber:globalContext.reporter];

        
    }
    return _sddBuilder;
}

- (void) configIndicatorViewSDD
{
    NSString * dsl = SDDOCLanguage(
    [IndicatorView ~[start]
     [start e:IndicatorViewStartState]
     [update e:IndicatorViewUpdateState
             x:IndicatorViewStopState]
     ]
    [start] -> [update] : LocationServiceUpdating
    [update] -> [start] : LocationServiceFree
                    
    
    );
    [self.sddBuilder hostSchedulerWithContext:self dsl:dsl];
}

- (void) IndicatorViewStartState
{
    self.locationUpdateIndicatorView.hidden = YES;
    self.locationUpdateIndicatorView.hidesWhenStopped = YES;
}

- (void) IndicatorViewUpdateState
{
    self.locationUpdateIndicatorView.hidden = NO;
    [self.locationUpdateIndicatorView startAnimating];
}

- (void) IndicatorViewStopState
{
    self.locationUpdateIndicatorView.hidden = NO;
    [self.locationUpdateIndicatorView stopAnimating];
}

- (void) configLocationContentLabelSDD
{
    NSString *dsl = SDDOCLanguage(
    [contentLabel ~[start]
     [start e:contentLabelStartState]
     [update e:contentLabelUpdateState]
     [error e:contentLabelErrorState]
     ]
                                  
    [start] -> [update] : LocationServiceUpdating
    [update] -> [error] : LocationServiceFailed
    [error] -> [update] : LocationServiceUpdating
                        
    );
    
    [self.sddBuilder hostSchedulerWithContext:self dsl:dsl];
}


- (void) contentLabelStartState
{
    self.locationContentLabel.text = @"当前没有收到任何地理位置";
}

- (void) contentLabelUpdateState:(id )content
{
    if ([content isKindOfClass:[CLLocation class]]) {
        CLLocation *location = content;
        self.locationContentLabel.enabled = YES;
        NSString *labelContent = [NSString stringWithFormat:@"当前经度为%@，纬度为%@",@(location.coordinate.latitude),@(location.coordinate.longitude)];
        if (![self.locationContentLabel.text isEqualToString:labelContent]) {
            self.locationContentLabel.text = labelContent;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self scheduleEvent:kLRServiceEventFree withParam:nil];
        });
    }
}

- (void) contentLabelErrorState:(NSError *)error
{
    self.locationContentLabel.enabled = NO;
    self.locationContentLabel.text = @"当前LBS服务出现错误";
}

- (IBAction)locationServiceSwitchUpdate:(id)sender {
    if (self.locationServiceSwitch.enabled) {
        if (self.locationServiceSwitch.on) {
            [self scheduleEvent:kLRServiceEventOpen withParam:nil];
        }else{
            [self scheduleEvent:kLRServiceEventClose withParam:nil];
        }
    }
}

- (void) openSwitch
{
}

- (void) offSwitch
{
}

- (void) enableSwitch
{
    self.locationServiceSwitch.enabled = YES;
}

- (void) disableSwitch
{
    self.locationServiceSwitch.enabled = NO;
}

- (void) setLocationServiceSwitchOnState
{
    self.locationServiceSwitch.on = YES;
    [self openLocationService];
}

- (void) setLocationServiceSwitchOffState
{
    self.locationServiceSwitch.on = NO;
    [self closeLocationService];
}

- (void) configLocationManagerSDD
{
    NSString* dsl = SDDOCLanguage
    (
     [locationManager ~[start]
      [start e:configLocationManager contentLabelStartState]
      [disabled e:closeLocationService disableSwitch IndicatorViewStartState contentLabelStartState]
      [enabled   ~[open]
       [open e:enableSwitch openLocationService ~[free]
        [free e:IndicatorViewStopState  setLocationServiceSwitchOnState]
        [update e:IndicatorViewUpdateState contentLabelUpdateState]
        ]
       
       [close e:setLocationServiceSwitchOffState contentLabelStartState IndicatorViewStartState]
       ]
      ]
     [close] -> [open]  : LocatonServiceOpen
     [open] -> [close]  : LocatonServiceClose
     [free] -> [update] : LocationServiceUpdating
     [update] -> [free] : LocationServiceFree
     [start] -> [enabled] : LocationServiceEnabled
     [start] -> [disabled] : LocationServiceDisabled
     [enabled] -> [disabled] :LocationServiceDisabled
     [disabled] -> [enabled] : LocationServiceEnabled
     
     );
    
    [self.sddBuilder hostSchedulerWithContext:self dsl:dsl];
    
}

- (void) configLocationManager
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        return;
    }
    
    CLLocationManager *aLocationManager = [CLLocationManager new];
    aLocationManager.delegate = self;
    self.locationManager = aLocationManager;
    
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
   // [self openLocationService];
}


- (void) openLocationService
{
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void) closeLocationService
{
    [self.locationManager stopUpdatingLocation];
}

- (void) scheduleEvent:(NSString *)event withParam:(nullable id)param
{
    [self.sddBuilder.epool scheduleEvent:event withParam:param];
}

#pragma mark CLLocationDelegate

- (void)  locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse|| status == kCLAuthorizationStatusAuthorizedAlways) {
        [self scheduleEvent:KLRServiceEventAuthorizationEnabled withParam:nil];
    }
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusNotDetermined) {
        [self scheduleEvent:KLRServiceEventAuthorizationDisabled withParam:nil];
    }
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *firstLocation = locations.firstObject;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self scheduleEvent:kLRServiceEventUpdating withParam:firstLocation];
    });
    
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self scheduleEvent:kLRServiceEventUpdateFailed withParam:error];
}

@end
