//
//  SDDSocketReporter.m
//  SDD
//
//  Created by 黎玉华 on 16/5/17.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import "SDDISocketReporter.h"
#import "SDDSchedulerBuilder.h"


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
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
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

- (void)willStartScheduler:(nonnull SDDScheduler *)scheduler {
    [NSJSONSerialization writeJSONObject:@{
                                           @"proto": @"start",
                                           @"dsl":   [scheduler sdd_DSL],
                                           }
                                toStream:_outputStream
                                 options:0
                                   error:nil];
}

- (void)didStopScheduler:(nonnull SDDScheduler *)scheduler {
    [NSJSONSerialization writeJSONObject:@{
                                           @"proto": @"stop",
                                           @"scheduler": [scheduler sdd_name],
                                           }
                                toStream:_outputStream
                                 options:0
                                   error:nil];
}

- (void)scheduler:(nonnull SDDScheduler *)scheduler didActivateState:(nonnull SDDState *)state withArgument:(nullable id)argument {
    [NSJSONSerialization writeJSONObject:@{
                                           @"proto": @"activate",
                                           @"scheduler": [scheduler sdd_name],
                                           @"state":     [state sdd_name],
                                           }
                                toStream:_outputStream
                                 options:0
                                   error:nil];
}

- (void)scheduler:(nonnull SDDScheduler *)scheduler didDeactivateState:(nonnull SDDState *)state {
    [NSJSONSerialization writeJSONObject:@{
                                           @"proto": @"deactivate",
                                           @"scheduler": [scheduler sdd_name],
                                           @"state":     [state sdd_name],
                                           }
                                toStream:_outputStream
                                 options:0
                                   error:nil];
}

- (void)scheduler:(nonnull SDDScheduler *)scheduler didOccurEvent:(nonnull SDDEvent *)event withArgument:(nullable id)argument {
    [NSJSONSerialization writeJSONObject:@{
                                           @"proto": @"event",
                                           @"value": event,
                                           }
                                toStream:_outputStream
                                 options:0
                                   error:nil];
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
