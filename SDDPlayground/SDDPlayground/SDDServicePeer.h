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
- (void)peer:(SDDServicePeer *)peer didReceiveDSL:(NSString *)dsl;
- (void)peer:(SDDServicePeer *)peer didActivateState:(NSString *)stateName atDSL:(NSString *)dslName;
- (void)peer:(SDDServicePeer *)peer didDeactivateState:(NSString *)stateName atDSL:(NSString *)dslName;
- (void)peer:(SDDServicePeer *)peer didReceiveEvent:(NSString *)event;
@end


@interface SDDServicePeer : NSObject
@property (weak) id<SDDServicePeerDelegate> delegate;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithInputStream:(NSInputStream *)iStream outputStream:(NSOutputStream *)oStream;

- (void)start;
- (void)stop;
@end
