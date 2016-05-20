//
//  SDDServicePeer.h
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

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
@end
