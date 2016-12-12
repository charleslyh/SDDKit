// SDDServicePeer.h
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

#import <Foundation/Foundation.h>

@class SDDServicePeer;

@protocol SDDServicePeerDelegate <NSObject>
- (void)peer:(SDDServicePeer *)peer scheduler:(NSString *)scheduler didStartWithDSL:(NSString *)dsl didActivates:(NSArray<NSString *>*)activates;
- (void)peer:(SDDServicePeer *)peer scheduler:(NSString *)scheduler didStopWithDeactivates:(NSArray<NSString *>*)deactivates;
- (void)peer:(SDDServicePeer *)peer scheduler:(NSString *)scheduler activates:(NSArray<NSString *> *)activates deactivates:(NSArray<NSString *> *)deactivates byEvent:(NSString *)event withScreenshotImage:(NSImage *)screenshot;

- (void)peer:(SDDServicePeer *)peer didReceiveEvent:(NSString *)event;
@end


extern NSString * const SDDServerPeerDidDisconnectNotification;

@interface SDDServicePeer : NSObject
@property (weak) id<SDDServicePeerDelegate> delegate;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithInputStream:(NSInputStream *)iStream outputStream:(NSOutputStream *)oStream;

- (void)start;
- (void)stop;

- (void)sendEventImitation:(NSString *)event;
@end
