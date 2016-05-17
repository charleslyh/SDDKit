//
//  SDDService.m
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import "SDDService.h"
#import "SDDServicePeer.h"
#import "TCPServer.h"

@interface SDDService()<TCPServerDelegate>
@end

@implementation SDDService {
    TCPServer *_tcpServer;
    NSMutableArray *_peers;
}

- (instancetype)init {
    if (self = [super init]) {
        _tcpServer = [[TCPServer alloc] init];
        _tcpServer.port = 9800;
        _tcpServer.type = @"_tcp.";
        _tcpServer.name = @"SDDService";
        _tcpServer.delegate = self;
    }
    return self;
}

- (void)TCPServer:(TCPServer *)server didReceiveConnectionFromAddress:(NSData *)address
      inputStream:(NSInputStream *)iStream
     outputStream:(NSOutputStream *)oStream
{
    SDDServicePeer *peer = [[SDDServicePeer alloc] initWithInputStream:iStream outputStream:oStream];
    [_peers addObject:peer];
    [peer start];
    
    [self.delegate service:self didReceiveConnection:peer];
}

- (void)didClosePeer:(SDDServicePeer *)peer {
    [_peers removeObject:peer];
    [peer stop];
}

- (void)start {
    _peers = [NSMutableArray array];
    
    NSError *error;
    if (![_tcpServer start:&error]) {
        NSLog(@"Error starting server: %@", error);
    } else {
        NSLog(@"Starting server on port %d", _tcpServer.port);
    }
}

- (void)stop {
    [_tcpServer stop];
    
    for (SDDServicePeer *c in _peers) {
        [c stop];
    }
    
    _peers = nil;
}

@end
