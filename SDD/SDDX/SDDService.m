// SDDService.m
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
