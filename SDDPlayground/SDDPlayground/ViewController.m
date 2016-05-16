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


@interface SDDSchedulerPresenter : NSObject
@property NSString *rootName;
@property NSMutableDictionary *descendants;
@property NSMutableDictionary *aliveFlags;
@end

@implementation SDDSchedulerPresenter

- (instancetype)init {
    if (self = [super init]) {
        _descendants = [NSMutableDictionary dictionary];
        _aliveFlags  = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)deactivateState:(NSString *)stateName {
    _aliveFlags[stateName] = @NO;
}

- (void)activateState:(NSString *)stateName {
    _aliveFlags[stateName] = @YES;
}

- (BOOL)isAliveState:(NSString *)name {
    return _aliveFlags[name] != nil && [_aliveFlags[name] boolValue];
}

- (NSAttributedString *)statesText {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    [self buildStatesText:text withStateNamed:_rootName];
    return text;
}

- (void)buildStatesText:(NSMutableAttributedString *)text withStateNamed:(NSString *)stateName {
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"["]];
    
    NSColor *color = [self isAliveState:stateName] ? [NSColor redColor] : [NSColor blackColor];
    static NSFont *font;
    if (!font) {
        font = [NSFont fontWithName:@"Menlo" size:14];
    }
    
    
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:stateName
                                                                 attributes:@{
                                                                              NSForegroundColorAttributeName: color,
                                                                              NSFontAttributeName: font,
                                                                              }]];
    
    NSArray *subStates = _descendants[stateName];
    if (subStates.count > 0) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];
    }
    
    for (NSString *name in subStates) {
        [self buildStatesText:text withStateNamed:name];
        
        if (name != subStates.lastObject) {
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        }
    }
    
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"]"]];
}


@end



void SDDPGHandleState(void *contextObj, sdd_state *state) {
    SDDSchedulerPresenter *presenter = (__bridge SDDSchedulerPresenter *)contextObj;
    
    NSString *name = SDDPGStringNameFromRawState(state);
    presenter.descendants[name] = [NSMutableArray array];
};

void SDDPGHandleDescendants(void *contextObj, sdd_state *parent, sdd_array *descendants) {
    SDDSchedulerPresenter *presenter = (__bridge SDDSchedulerPresenter *)contextObj;
    
    NSString *parentName = SDDPGStringNameFromRawState(parent);
    NSMutableArray *subNames = presenter.descendants[parentName];
    for (int i=0; i<sdd_array_count(descendants); ++i) {
        sdd_state *subState = sdd_array_at(descendants, i, sdd_yes);
        [subNames addObject:SDDPGStringNameFromRawState(subState)];
    }
}

void SDDPGHandleTransition(void *contextObj, sdd_transition *t) {}

void SDDPGHandleRootState(void *contextObj, sdd_state *root) {
    SDDSchedulerPresenter *presenter = (__bridge SDDSchedulerPresenter *)contextObj;
    
    presenter.rootName = SDDPGStringNameFromRawState(root);
}


@interface ViewController()<SDDServiceDelegate, SDDServicePeerDelegate, NSTableViewDataSource, NSTabViewDelegate>
@property (weak) IBOutlet NSTableView *historiesTableView;
@property IBOutlet NSTextView *stockMessagesView;

@property NSMutableArray *histories;
@end

@implementation ViewController {
    SDDService *_service;
    
    NSString     *_rootName;
    NSDictionary *_descendants;
    NSMutableDictionary *_aliveFlags;
    
    NSMutableDictionary *_presenters;
}

- (void)service:(SDDService *)service didReceiveConnection:(SDDServicePeer *)connection {
    connection.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _presenters = [NSMutableDictionary dictionary];
    
    _service = [[SDDService alloc] init];
    _service.delegate = self;
    [_service start];
    
    _histories = [NSMutableArray array];
}

- (void)peer:(SDDServicePeer *)peer didStartSchedulerWithDSL:(NSString *)dsl {
    SDDSchedulerPresenter *presenter = [[SDDSchedulerPresenter alloc] init];
    
    sdd_parser_callback callback;
    callback.context           = (__bridge void *)presenter;
    callback.stateHandler      = &SDDPGHandleState;
    callback.clusterHandler    = &SDDPGHandleDescendants;
    callback.transitionHandler = &SDDPGHandleTransition;
    callback.completionHandler = &SDDPGHandleRootState;
    sdd_parse([dsl UTF8String], &callback);
    
    _presenters[presenter.rootName] = presenter;
    
    [self syncTextView];

    [_histories addObject:[NSString stringWithFormat:@"[L] %@", presenter.rootName]];
    [self syncHistoriesTableView];
}

- (void)peer:(SDDServicePeer *)peer didStopSchedulerNamed:(NSString *)schedulerName {
    [_presenters removeObjectForKey:schedulerName];
    [self syncTextView];
    
    [_histories addObject:[NSString stringWithFormat:@"[S] %@", schedulerName]];
    [self syncHistoriesTableView];
}

- (void)peer:(SDDServicePeer *)peer didActivateState:(NSString *)stateName forSchedulerNamed:(NSString *)schedulerName {
    [_presenters[schedulerName] activateState:stateName];
    [self syncTextView];
    
    [_histories addObject:[NSString stringWithFormat:@"[A] %@.%@", schedulerName, stateName]];
    [self syncHistoriesTableView];
}

- (void)peer:(SDDServicePeer *)peer didDeactivateState:(NSString *)stateName forSchedulerNamed:(NSString *)schedulerName {
    [_presenters[schedulerName] deactivateState:stateName];
    [self syncTextView];

    [_histories addObject:[NSString stringWithFormat:@"[D] %@.%@", schedulerName, stateName]];
    [self syncHistoriesTableView];
}

- (void)peer:(SDDServicePeer *)peer didReceiveEvent:(NSString *)event {
    [_histories addObject:[NSString stringWithFormat:@"[E] %@", event]];
    [self syncHistoriesTableView];
}

- (void)syncHistoriesTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_historiesTableView reloadData];
    });
}

- (void)syncTextView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.stockMessagesView.textStorage setAttributedString:[[NSAttributedString alloc] init]];
        for (NSString *key in _presenters.allKeys) {
            SDDSchedulerPresenter *presenter = _presenters[key];

            NSAttributedString *text = [presenter statesText];
            
            [self.stockMessagesView.textStorage appendAttributedString:text];
            [self.stockMessagesView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
    });
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _histories.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"HistoryCellView" owner:self];
    cellView.textField.stringValue = _histories[row];
    
    return cellView;
}

@end
