// SDDISocketReporter.m
//
// Copyright (c) 2016 CharlesLiyh
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>
#import "SDDISocketReporter.h"
#import "SDDSchedulerBuilder.h"


@interface SDDISocketReporter ()<NSStreamDelegate>
@property (nonatomic) BOOL screenshotEnabled;
@end

@implementation SDDISocketReporter {
    NSString *_host;
    uint16_t  _port;
    
    NSInputStream *_istream;
    uint8_t _buffer[16<<10];
    NSInteger _nextWritingPos;
    
    NSOutputStream *_ostream;
    NSMutableArray *_outputPackets;
    dispatch_semaphore_t _outputSemaphore;
}

- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port {
    if (self = [super init]) {
        _host = host;
        _port = port;
        _delegate = nil;
        _outputPackets = [NSMutableArray array];
        _outputSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)setupNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)_host, _port, &readStream, &writeStream);
    _istream = (__bridge NSInputStream *)readStream;
    _ostream = (__bridge NSOutputStream *)writeStream;
    
    _istream.delegate  = self;
    _ostream.delegate = self;
    
    [_istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)openSendingLoop {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (_ostream != nil) {
            dispatch_semaphore_wait(_outputSemaphore, DISPATCH_TIME_FOREVER);
            if (_outputPackets.count <= 0) {
                break;
            }
            
            @synchronized (_outputPackets) {
                if (_outputPackets.count > 0) {
                    NSDictionary *packet = _outputPackets.firstObject;
                    [_outputPackets removeObjectAtIndex:0];
                    
                    [NSJSONSerialization writeJSONObject:packet toStream:_ostream options:0 error:nil];
                }
            }
        }
    });
}

- (void)setScreenshotForTransitionEnabled:(BOOL)enabled {
    self.screenshotEnabled = enabled;
}

- (void)closeSendingLoop {
    dispatch_semaphore_signal(_outputSemaphore);
}

- (void)start {
    [self setupNetworkCommunication];
    
    [_istream open];
    [_ostream open];

    [self openSendingLoop];
}

- (void)stop {
    [self closeSendingLoop];
    
    [_ostream close];
    [_istream close];
}

- (void)sendPacketWithProto:(NSString *)proto body:(NSDictionary *)body {
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    object[@"proto"] = proto;
    object[@"body"]  = body;
    
    @synchronized (_outputPackets) {
        [_outputPackets addObject:object];
        dispatch_semaphore_signal(_outputSemaphore);
    }
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
    
    if (self.screenshotEnabled) {
        UIImage *screenshot = [self captureFullScreen];
        if (screenshot != nil) {
            NSData *ssData = UIImageJPEGRepresentation(screenshot, 0.75);
            imageString = [ssData base64EncodedStringWithOptions:0];
        }
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

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == _istream) {
                NSInteger len;
                while ([_istream hasBytesAvailable]) {
                    len = [_istream read:_buffer + _nextWritingPos maxLength:sizeof(_buffer) - _nextWritingPos];
                    _nextWritingPos += len;
                    _buffer[_nextWritingPos] = 0;
                    if (len > 0) {
                        BOOL hasMorePacket = YES;
                        while(hasMorePacket && _nextWritingPos > 0) {
                            hasMorePacket = NO;
                            NSData *data;
                            NSInteger k = 0;
                            for (NSInteger i=0; i<_nextWritingPos; ++i) {
                                if (_buffer[i] == ' ')
                                    continue;
                                
                                if (_buffer[i] == '{') {
                                    k++;
                                } else if (_buffer[i] == '}') {
                                    k--;
                                    if (k==0) {
                                        data = [NSData dataWithBytes:_buffer length:i+1];
                                        memmove(_buffer, _buffer + i + 1, _nextWritingPos - i);
                                        _nextWritingPos = _nextWritingPos - i - 1;
                                        hasMorePacket = YES;
                                        break;
                                    }
                                }
                            }
                            
                            NSDictionary *object;
                            if (data) {
                                object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                            }
                            
                            if (nil != object) {
                                NSString *proto    = object[@"proto"];
                                NSDictionary *body = object[@"body"];
                                
                                if ([proto isEqualToString:@"imitation"]) {
                                    [self.delegate reporter:self didReceiveEventImitation:body[@"event"]];
                                }
                            }
                        }
                    }
                }
            }
            
            break;
            
        case NSStreamEventHasSpaceAvailable:
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Stream did encounter end");
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
            
        default:
            break;
    }
}

@end
