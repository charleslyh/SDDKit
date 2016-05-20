//
//  VCPDynamic.h
//  YYMusicshow
//
//  Created by 黎玉华 on 16/3/16.
//  Copyright © 2016年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VCPDynamic <NSObject>
+ (NSArray*)vcp_propertyNames;//目前属于非线程安全的操作
@end


/*
 很多时候，从服务器拿到的数据里，其实已经包含了可直接对应于属性的数据，例如
 {
    "yyuid": 1234,
    "nick":  "Charles",
    "result": 0,
    ……
 }
 如果属性数量非常多，使用动态属性扩展(VCPDynamic)来逐个设置属性值时，还是非常繁琐的。一个较好的办法是，让业务层对象直接持有这个服务器返回的json对象，然后在动态属性解析时，直接从该对象中提取所需数据。下面对于NSObject的分类方法就支持了这种处理思路。
 */
@interface NSObject (VCPDynamic)
/*
 @param reliant
 用于表示、存放表示动态属性数据的字典对象
 @param keyMap
 有时候后台接口所使用的属性命名和客户端的业务命名是不一样的，keyMap用于进行属性名映射，例如，后台返回的数据中，用yy_uid表示用户id，而业务实现中，希望用简化名称uid来命名这个属性，则可以通过传递
 @{
    @"uid": @"yy_uid",
 }
 这个keyMap来告知
 */
- (void)vcp_setReliantObject:(NSDictionary*)reliant;
- (void)vcp_setReliantObject:(NSDictionary *)reliant withKeyMap:(NSDictionary*)keyMap;
- (NSDictionary*)reliantObject;
@end
