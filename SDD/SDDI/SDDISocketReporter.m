//
//  SDDSocketReporter.m
//  SDD
//
//  Created by 黎玉华 on 16/5/17.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDDISocketReporter.h"
#import "SDDSchedulerBuilder.h"

@interface SDDISocketReporter ()<NSStreamDelegate>
@end


@implementation SDDISocketReporter {
    NSString *_host;
    uint16_t  _port;
    
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}

- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port {
    if (self = [super init]) {
        _host = host;
        _port = port;
    }
    return self;
}

- (void)setupNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)_host, _port, &readStream, &writeStream);
    _inputStream = (__bridge NSInputStream *)readStream;
    _outputStream = (__bridge NSOutputStream *)writeStream;
    
    _inputStream.delegate  = self;
    _outputStream.delegate = self;
    
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)start {
    [self setupNetworkCommunication];
    
    [_inputStream open];
    [_outputStream open];
}

- (void)stop {
    [_outputStream close];
    [_inputStream close];
}

- (void)sendPacketWithProto:(NSString *)proto body:(NSDictionary *)body {
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    object[@"proto"] = proto;
    object[@"body"]  = body;
    [NSJSONSerialization writeJSONObject:object toStream:_outputStream options:0 error:nil];
}

- (NSArray<NSString *>*)namesFromStates:(NSArray<SDDState *> *)states {
    NSMutableArray *names = [NSMutableArray array];
    for (SDDState *s in states) {
        [names addObject:s.sddName];
    }
    
    return names;
}

- (void)didStartScheduler:(SDDScheduler *)scheduler activates:(NSArray<SDDState *> *)activates {
    [self sendPacketWithProto:@"start"
                         body:@{
                                @"scheduler": scheduler.sddIdentifier,
                                @"dsl":       scheduler.sddDSL,
                                @"activates": [self namesFromStates:activates],
                                }];
}

- (void)didStopScheduler:(SDDScheduler *)scheduler deactivates:(NSArray<SDDState *> *)deactivates {
    [self sendPacketWithProto:@"stop"
                         body:@{
                                @"scheduler":   scheduler.sddIdentifier,
                                @"deactivates": [self namesFromStates:deactivates],
                                }];
}

- (UIImage *)captureFullScreen {
    UIView *window = [[UIApplication sharedApplication] keyWindow];
    
    // 非retina屏已经不在考虑之中啦……
    CGRect bounds = CGRectMake(0, 0,
                               window.bounds.size.width  / [UIScreen mainScreen].scale / 2,
                               window.bounds.size.height / [UIScreen mainScreen].scale / 2) ;
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, [UIScreen mainScreen].scale);
    [window drawViewHierarchyInRect:bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)scheduler:(SDDScheduler *)scheduler
        activates:(NSArray<SDDState *> *)activates
      deactivates:(NSArray<SDDState *> *)deactivates
          byEvent:(SDDEvent *)event
{
    NSString *imageString = @"";
    UIImage *screenshot = [self captureFullScreen];
    if (screenshot != nil) {
        NSData *ssData = UIImageJPEGRepresentation(screenshot, 0.75);
        imageString = [ssData base64EncodedStringWithOptions:0];
    }

    [self sendPacketWithProto:@"transit"
                         body:@{
                                @"scheduler":   scheduler.sddIdentifier,
                                @"event":       event,
                                @"activates":   [self namesFromStates:activates],
                                @"deactivates": [self namesFromStates:deactivates],
                                @"screenshot":  imageString,
                                }];
}

- (void)onEvent:(nonnull SDDEvent *)event withParam:(nullable id)param {
    [self sendPacketWithProto:@"event" body:@{ @"value": event }];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            break;
            
        case NSStreamEventHasSpaceAvailable:
            break;
            
        case NSStreamEventNone:
            break;
            
        default:
            NSLog(@"Unknown event");
    }
}

@end
