//
//  SDDService.h
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SDDService, SDDServicePeer;

@protocol SDDServiceDelegate <NSObject>
- (void)service:(SDDService *)service didReceiveConnection:(SDDServicePeer *)connection;
@end

@interface SDDService : NSObject
@property (weak) id<SDDServiceDelegate> delegate;

- (void)start;
- (void)stop;

@end
