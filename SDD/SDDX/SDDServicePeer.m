//
//  SDDServicePeer.m
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SDDServicePeer.h"

NSString * const SDDServerPeerDidDisconnectNotification = @"SDDServerPeerDidDisconnectNotification";


@interface SDDServicePeer() <NSStreamDelegate>
@end

@implementation SDDServicePeer {
    NSInputStream  *_istream;
    NSOutputStream *_ostream;
    
    uint8_t _buffer[4<<20];
    NSInteger _nextWritingPos;
}

- (instancetype)initWithInputStream:(NSInputStream *)iStream outputStream:(NSOutputStream *)oStream {
    if (self = [super init]) {
        _istream = iStream;
        _ostream = oStream;
        _istream.delegate  = self;
        _ostream.delegate = self;
    }
    return self;
}

- (void)start {
    [_istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    _nextWritingPos = 0;
    
    [_istream open];
    [_ostream open];
}

- (void)stop {
    [_istream close];
    [_ostream close];
}

- (void)sendEventImitation:(NSString *)event {
    [NSJSONSerialization writeJSONObject:@{
                                          @"proto": @"imitation",
                                          @"body":  @{ @"event": event }
                                          }
                                toStream:_ostream
                                 options:0
                                   error:nil];
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
                                NSString *protocol = object[@"proto"];
                                NSDictionary *body = object[@"body"];
                                
                                if ([protocol isEqualToString:@"start"]) {
                                    [self.delegate peer:self
                                              scheduler:body[@"scheduler"]
                                        didStartWithDSL:body[@"dsl"]
                                           didActivates:body[@"activates"]];
                                } else if ([protocol isEqualToString:@"stop"]) {
                                    [self.delegate peer:self
                                              scheduler:body[@"scheduler"]
                                 didStopWithDeactivates:body[@"deactivates"]];
                                } else if ([protocol isEqualToString:@"transit"]){
                                    NSString *base64String = body[@"screenshot"];
                                    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                                    NSImage *screenshot = [[NSImage alloc] initWithData:imageData];

                                    [self.delegate peer:self
                                              scheduler:body[@"scheduler"]
                                              activates:body[@"activates"]
                                            deactivates:body[@"deactivates"]
                                                byEvent:body[@"event"]
                                    withScreenshotImage:screenshot];
                                } else if ([protocol isEqualToString:@"event"]) {
                                    [self.delegate peer:self didReceiveEvent:body[@"value"]];
                                }
                            }
                        }
                    }
                }
            }
            
            break;
            
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Stream did encounter end");
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SDDServerPeerDidDisconnectNotification object:self];
            
            break;
            
        default:
            break;
    }
}

@end
