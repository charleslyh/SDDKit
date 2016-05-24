//
//  SDDPGImageViewController.m
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/24.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import "SDDPGSequenceDiagramController.h"
#import "AFNetworking.h"

@interface SDDPGSequenceDiagramController ()
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;
@end

@implementation SDDPGSequenceDiagramController {
    AFHTTPSessionManager* _sessionManager;
}

/*
 AFNetworking  默认不支持对contentType为text/html的结果进行json解析，而我们的后台服务并没进行恰当处理。所以必须在客户端手动增加从text/html到json格式解析的支持
 @see http://blog.csdn.net/nyh1006/article/details/25068255
 */
- (void)setupJsonResponseSerializerForManager {
    AFJSONResponseSerializer* responseSerializer = [[AFJSONResponseSerializer alloc] init];
    NSMutableSet* acceptableContentTypes = [responseSerializer.acceptableContentTypes mutableCopy];
    [acceptableContentTypes addObject:@"text/html"];
    [acceptableContentTypes addObject:@"application/x-json"];
    responseSerializer.acceptableContentTypes = acceptableContentTypes;
    _sessionManager.responseSerializer = responseSerializer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.loadingIndicator startAnimation:nil];
    
    NSURL* baseURL = [NSURL URLWithString:@"https://www.websequencediagrams.com"];
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    [self setupJsonResponseSerializerForManager];
    
    NSDictionary *parameters = @{
                                 @"message": self.stringValue,
                                 @"style":   @"modern-blue",
                                 @"width":   @"1024",
                                 @"apiVersion": @"1",
                                 };
    
    [_sessionManager POST:@"index.php" parameters:parameters success:^(NSURLSessionDataTask * task, NSDictionary *response) {
        NSString *imageURLString = response[@"img"];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.websequencediagrams.com/index.php%@", imageURLString]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [[NSImage alloc] initWithData:imageData];
                [self.loadingIndicator stopAnimation:nil];
            });
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.loadingIndicator stopAnimation:nil];
        NSLog(@"response failure");
    }];
    // Do view setup here.
}

@end
