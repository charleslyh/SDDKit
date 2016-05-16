//
//  SDDServicePeer.m
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import "SDDServicePeer.h"

@interface SDDServicePeer() <NSStreamDelegate>
@end

@implementation SDDServicePeer {
    NSInputStream  *_istream;
    NSOutputStream *_ostream;
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
    
    [_istream open];
    [_ostream open];
}

- (void)stop {
    [_istream close];
    [_ostream close];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == _istream) {
                uint8_t buffer[1024];
                NSInteger len;
                
                while ([_istream hasBytesAvailable]) {
                    len = [_istream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            
                            NSArray* components = [output componentsSeparatedByString:@":"];
                            if (components.count == 2) {
                                NSString *protocol = components[0];
                                NSString *content  = [components[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                if ([protocol isEqualToString:@"dsl"]) {
                                    [self.delegate peer:self didReceiveDSL:content];
                                } else if ([protocol isEqualToString:@"activate"]) {
                                    [self.delegate peer:self didActivateStateNamed:content];
                                } else if ([protocol isEqualToString:@"deactivate"]) {
                                    [self.delegate peer:self didDeactivateStateNamed:content];
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
            
            break;
            
        default:
            NSLog(@"Unknown event");
    }
}

@end
