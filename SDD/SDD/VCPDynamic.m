// VCPDynamic.m
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

#import <objc/runtime.h>
#import "VCPDynamic.h"

@implementation NSString (VCPDynamic)

- (BOOL)vcp_isSetterName {
    // 标准的属性设置方法是由"set"作为前缀的，占用了3个字符；且设置方法的名称一定是以冒号结束，此为另一个字符；最后，设置方法不可能仅仅是"set:"这样的命名，所以有意义的属性设置方法至少是这样的形式"setX:"。判断是否为setter的首要条件是长度是否大于4（3+1）。只有满足这个条件是，进行"set"前缀判断和进行字符串截取才是安全的。
    // 某些方法和set是重名的，例如"setupWithObject:"，它满足长度、"set"前缀的要求，但显然不是一个setter方法，所以需要一个额外的大写字母来排除这种特例
    return self.length > (3 + 1) && [self hasPrefix:@"set"] && isupper([self characterAtIndex:3]);
}

- (NSString*)vcp_normalPropertyName {
    NSMutableString* propertyName = [self mutableCopy];
    if ([propertyName vcp_isSetterName]) {
        // Remove the ':' at the end
        [propertyName deleteCharactersInRange:NSMakeRange(propertyName.length - 1, 1)];
        
        // Remove the 'set' prefix
        [propertyName deleteCharactersInRange:NSMakeRange(0, 3)];
    }
    
    // 如果属性名是以大写字母开头，处理会变得复杂。为了避免无意义的复杂化，最好的办法就是将它们统一转换为小写字符串。虽然会带来大小写冲突问题，但是谁会去写两个只是大小写不一样的属性呢？这种程序猿本身就该挨揍。
    return [propertyName lowercaseString];
}

@end


static void* kVCPDynamicPropertiesMapKey = &kVCPDynamicPropertiesMapKey;
static void* kVCPDynamicPropertiesKeyMapObjectKey = &kVCPDynamicPropertiesKeyMapObjectKey;

@implementation NSObject (CLHReliantDynamic)

- (void)vcp_setReliantObject:(NSDictionary *)reliant {
    [self vcp_setReliantObject:reliant withKeyMap:nil];
}

- (void)vcp_setReliantObject:(NSDictionary *)reliant withKeyMap:(NSDictionary *)keyMap {
    NSAssert([self conformsToProtocol:@protocol(VCPDynamic)], @"%@ 必须符合VCPDynamic协议才可以使用 [NSObject(VCPDynamic) vcp_setReliantObject]方法进行属性基值设置", self);
    
    objc_setAssociatedObject(self, kVCPDynamicPropertiesMapKey, [reliant mutableCopy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableDictionary* propertyKeys = [NSMutableDictionary dictionary];
    for (NSString* key in reliant.allKeys) {
        if ([[[self class] vcp_propertyNames] containsObject:key]) {
            propertyKeys[key.lowercaseString] = key;
        }
    }
    
    for (NSString* originalKey in keyMap.allKeys) {
        propertyKeys[originalKey.lowercaseString] = keyMap[originalKey];
    }

    objc_setAssociatedObject(self, kVCPDynamicPropertiesKeyMapObjectKey, propertyKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary*)reliantObject {
    return objc_getAssociatedObject(self, kVCPDynamicPropertiesMapKey);
}

@end


id VCPAutoDictionaryGetter(id self, SEL _cmd) {
    NSDictionary* properties = objc_getAssociatedObject(self, kVCPDynamicPropertiesMapKey);
    if (properties != nil) {
        NSString* propertyName = [NSStringFromSelector(_cmd) vcp_normalPropertyName];
        
        NSDictionary* keyMap = objc_getAssociatedObject(self, kVCPDynamicPropertiesKeyMapObjectKey);
        if (keyMap != nil) {
            NSString* key = keyMap[propertyName];
            if (key != nil) {
                propertyName = key;
            }
        }
        
        return properties[propertyName];
    }
    return nil;
}

void VCPAutoDictionarySetter(id self, SEL _cmd, id value) {
    NSMutableDictionary* properties = objc_getAssociatedObject(self, kVCPDynamicPropertiesMapKey);
    if (properties == nil) {
        properties = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kVCPDynamicPropertiesMapKey, properties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSString* propertyName = [NSStringFromSelector(_cmd) vcp_normalPropertyName];
    
    NSDictionary* keyMap = objc_getAssociatedObject(self, kVCPDynamicPropertiesKeyMapObjectKey);
    if (keyMap != nil) {
        NSString* key = keyMap[propertyName];
        if (key != nil) {
            propertyName = key;
        }
    }
    
    properties[propertyName] = value;
}


BOOL VCPResolveInstanceMethod(id<VCPDynamic> self, SEL _cmd) {
    NSString* name = NSStringFromSelector(_cmd);
    BOOL isSetter = [name vcp_isSetterName];
    name = [name vcp_normalPropertyName];
    
    NSMutableArray* lowerNames = [NSMutableArray array];
    for (NSString* key in [self vcp_propertyNames]) {
        [lowerNames addObject:[key lowercaseString]];
    }
    
    if ([lowerNames containsObject:name]) {
        if (isSetter) {
            class_addMethod([self class], _cmd, (IMP)VCPAutoDictionarySetter, "v@:@");
        } else {
            class_addMethod([self class], _cmd, (IMP)VCPAutoDictionaryGetter, "@@:");
        }
    }
    
    return NO;
}

@implementation NSObject (VCPDynamicPropertySupport)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(resolveInstanceMethod:);
        SEL swizzledSelector = @selector(VCPDynamicPropertis_resolveInstanceMethod:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

+ (BOOL)VCPDynamicPropertis_resolveInstanceMethod:(SEL)selector {
    if ([self conformsToProtocol:@protocol(VCPDynamic)] && VCPResolveInstanceMethod((id<VCPDynamic>)self, selector)) {
        return YES;
    }
    
    // 如果无法经由VCPDynamic来决议动态属性，则必须将处理权交还给+[NSObject resolveInstanceMethod:]方法
    return [self VCPDynamicPropertis_resolveInstanceMethod:selector];
}

@end
