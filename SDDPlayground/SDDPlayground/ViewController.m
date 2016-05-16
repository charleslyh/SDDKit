//
//  ViewController.m
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import "ViewController.h"
#import "SDDService.h"
#import "SDDServicePeer.h"
#import "SDDX.h"


NSString * SDDPGStringNameFromRawState(sdd_state *s) {
    return [NSString stringWithCString:s->name encoding:NSASCIIStringEncoding];
}


@interface SDDPGParserContext : NSObject
@property NSString *rootName;
@property NSMutableDictionary *descendants;
@end

@implementation SDDPGParserContext

- (instancetype)init {
    if (self = [super init]) {
        _descendants = [NSMutableDictionary dictionary];
    }
    return self;
}

@end



void SDDPGHandleState(void *contextObj, sdd_state *state) {
    SDDPGParserContext *context = (__bridge SDDPGParserContext *)contextObj;
    
    NSString *name = SDDPGStringNameFromRawState(state);
    context.descendants[name] = [NSMutableArray array];
};

void SDDPGHandleDescendants(void *contextObj, sdd_state *parent, sdd_array *descendants) {
    SDDPGParserContext *context = (__bridge SDDPGParserContext *)contextObj;
    
    NSString *parentName = SDDPGStringNameFromRawState(parent);
    NSMutableArray *subNames = context.descendants[parentName];
    for (int i=0; i<sdd_array_count(descendants); ++i) {
        sdd_state *subState = sdd_array_at(descendants, i, sdd_yes);
        [subNames addObject:SDDPGStringNameFromRawState(subState)];
    }
}

void SDDPGHandleTransition(void *contextObj, sdd_transition *t) {}

void SDDPGHandleRootState(void *contextObj, sdd_state *root) {
    SDDPGParserContext *context = (__bridge SDDPGParserContext *)contextObj;
    
    context.rootName = SDDPGStringNameFromRawState(root);
}


@interface ViewController()<SDDServiceDelegate, SDDServicePeerDelegate>
@property IBOutlet NSTextView *stockMessagesView;
@end

@implementation ViewController {
    SDDService *_service;
    
    NSString     *_rootName;
    NSDictionary *_descendants;
    NSMutableDictionary *_aliveFlags;
}

- (void)service:(SDDService *)service didReceiveConnection:(SDDServicePeer *)connection {
    connection.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _service = [[SDDService alloc] init];
    _service.delegate = self;
    [_service start];
}

- (void)peer:(SDDServicePeer *)peer didReceiveDSL:(NSString *)dsl {
    SDDPGParserContext *context = [[SDDPGParserContext alloc] init];
    
    sdd_parser_callback callback;
    callback.context           = (__bridge void *)context;
    callback.stateHandler      = &SDDPGHandleState;
    callback.clusterHandler    = &SDDPGHandleDescendants;
    callback.transitionHandler = &SDDPGHandleTransition;
    callback.completionHandler = &SDDPGHandleRootState;

    sdd_parse([dsl UTF8String], &callback);
    
    _rootName    = context.rootName;
    _descendants = context.descendants;
    _aliveFlags  = [NSMutableDictionary dictionary];
    
    [self syncTextView];
}

- (BOOL)isAliveState:(NSString *)name {
    return _aliveFlags[name] != nil && [_aliveFlags[name] boolValue];
}

- (void)peer:(SDDServicePeer *)peer didActivateStateNamed:(NSString *)stateName {
    _aliveFlags[stateName] = @YES;
    [self syncTextView];
}

- (void)peer:(SDDServicePeer *)peer didDeactivateStateNamed:(NSString *)stateName {
    _aliveFlags[stateName] = @NO;
    [self syncTextView];
}

- (void)buildStatesText:(NSMutableAttributedString *)text withStateNamed:(NSString *)stateName {
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"["]];
    
    NSColor *color = [self isAliveState:stateName] ? [NSColor redColor] : [NSColor blackColor];
    
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:stateName
                                                                 attributes:@{
                                                                              NSForegroundColorAttributeName: color
                                                                              }]];
    
    NSArray *subStates = _descendants[stateName];
    if (subStates.count > 0) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    
    for (NSString *name in subStates) {
        [self buildStatesText:text withStateNamed:name];
    }
    
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"]"]];
}

- (void)syncTextView {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
        [self buildStatesText:text withStateNamed:_rootName];
        [self.stockMessagesView.textStorage setAttributedString:text];
    });
}

@end
