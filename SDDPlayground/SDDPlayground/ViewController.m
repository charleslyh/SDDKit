//
//  ViewController.m
//  SDDPlayground
//
//  Created by 黎玉华 on 16/5/14.
//  Copyright © 2016年 Flash. All rights reserved.
//

#import <SDDX/SDDX.h>
#import "ViewController.h"


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

- (void)resetAlives {
    _aliveFlags = [NSMutableDictionary dictionary];
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
    [self buildStatesText:text withStateNamed:_rootName ident:0];
    return text;
}

- (void)buildStatesText:(NSMutableAttributedString *)text withStateNamed:(NSString *)stateName ident:(NSInteger)ident {
    static NSString *kIdentString = @"    ";
    
    for (NSInteger i=0; i<ident; ++i) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:kIdentString]];
    }
    
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
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    
    for (NSString *name in subStates) {
        [self buildStatesText:text withStateNamed:name ident:ident+1];
        
        if (name != subStates.lastObject) {
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
    }
    
    if (subStates.count >0) {
        [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
        for (NSInteger i=0; i<ident; ++i) {
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:kIdentString]];
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


@interface SDDPGHistoryItem : NSObject<NSCopying>
@property NSString *shortString;
@property NSString *longString;
@property NSImage *optioanlImage;
@end

@implementation SDDPGHistoryItem

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end


@interface ViewController()<SDDServiceDelegate, SDDServicePeerDelegate, NSTableViewDataSource, NSTabViewDelegate>
@property IBOutlet NSTextView *stockMessagesView;
@property (weak) IBOutlet NSTableView *historiesTableView;
@property (weak) IBOutlet NSButton *filterEButton;
@property (weak) IBOutlet NSTextField *histroyLabel;
@property (weak) IBOutlet NSImageView *screenshotImageView;

@property NSMutableArray<SDDPGHistoryItem *> *historyItems;
@property NSMutableDictionary<NSString *, SDDSchedulerPresenter *> *presenters;
@end

@implementation ViewController {
    SDDService *_service;
    
    NSMutableArray<SDDPGHistoryItem*> *_filteredHistories;
    BOOL _wantEvents;
    
    NSMutableDictionary *_presenterUpdates;
}

- (void)service:(SDDService *)service didReceiveConnection:(SDDServicePeer *)connection {
    connection.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.screenshotImageView setImageScaling:NSImageScaleProportionallyDown];
    
    [self resetContent];
    
    _service = [[SDDService alloc] init];
    _service.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
                                                      object:_historiesTableView
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
    {
        [self syncHistoryLabelForSelectionChange];
        [self syncScreenshotImageViewByHistorySelection];
        [self rebuildStatePresentations];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:SDDServerPeerDidDisconnectNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note)
    {
        [self resetContent];
    }];
    
    _wantEvents = YES;
    _filterEButton.state = _wantEvents ? NSOnState : NSOffState;
    [self syncHistoryLabelForSelectionChange];

    [_service start];
}

- (void)resetContent {
    _historyItems     = [NSMutableArray array];
    _presenters       = [NSMutableDictionary dictionary];
    _presenterUpdates = [NSMutableDictionary dictionary];
    
    [self syncHistoriesTableView];
    [self syncTextView];
}

- (void)syncScreenshotImageViewByHistorySelection {
    static NSInteger NoneSelected = -1;
    NSInteger row = _historiesTableView.selectedRow;
    if (row == NoneSelected) {
        self.screenshotImageView.image = nil;
    } else {
        self.screenshotImageView.image = _filteredHistories[row].optioanlImage;
    }
}

- (void)syncHistoryLabelForSelectionChange {
    static NSInteger NoneSelected = -1;
    NSInteger row = _historiesTableView.selectedRow;
    if (row == NoneSelected) {
        self.histroyLabel.stringValue = @"请选中事件列表";
    } else {
        self.histroyLabel.stringValue = _filteredHistories[row].longString;
    }
}

- (NSString *)namesFromStates:(NSArray<NSString *> *)stateNames {
    return [stateNames componentsJoinedByString:@","];
}

- (void)peer:(SDDServicePeer *)peer scheduler:(NSString *)scheduler didStartWithDSL:(NSString *)dsl didActivates:(NSArray<NSString *> *)activates {
    SDDSchedulerPresenter *presenter = [[SDDSchedulerPresenter alloc] init];
    
    sdd_parser_callback callback;
    callback.context           = (__bridge void *)presenter;
    callback.stateHandler      = &SDDPGHandleState;
    callback.clusterHandler    = &SDDPGHandleDescendants;
    callback.transitionHandler = &SDDPGHandleTransition;
    callback.completionHandler = &SDDPGHandleRootState;
    sdd_parse([dsl UTF8String], &callback);
    
    SDDPGHistoryItem *item = [SDDPGHistoryItem new];
    item.shortString = [NSString stringWithFormat:@"<L> [%@]", presenter.rootName];
    item.longString  = [NSString stringWithFormat:@"<Launch  > [%@] {%@}", presenter.rootName, [self namesFromStates:activates]];
    [_historyItems addObject:item];
    
    [self syncUIByAddingItem:item presenterUpdate:^(ViewController *wself) {
        wself.presenters[scheduler] = presenter;
        
        [presenter resetAlives];
        for (NSString *sname in activates) {
            [presenter activateState:sname];
        }
    }];
}

- (void)peer:(SDDServicePeer *)peer scheduler:(NSString *)scheduler didStopWithDeactivates:(NSArray<NSString *> *)deactivates {
    SDDSchedulerPresenter *presenter = self.presenters[scheduler];
    
    SDDPGHistoryItem *item = [SDDPGHistoryItem new];
    item.shortString = [NSString stringWithFormat:@"<S> [%@]", presenter.rootName];
    item.longString  = [NSString stringWithFormat:@"<Stop   > [%@] {%@}", presenter.rootName, [self namesFromStates:deactivates]];
    [_historyItems addObject:item];
    
    [self syncUIByAddingItem:item presenterUpdate:^(ViewController *wself) {
        for (NSString *sname in deactivates) {
            [presenter deactivateState:sname];
        }
        
        [wself.presenters removeObjectForKey:scheduler];
    }];
}

- (void)peer:(SDDServicePeer *)peer scheduler:(NSString *)scheduler activates:(NSArray<NSString *> *)activates deactivates:(NSArray<NSString *> *)deactivates byEvent:(NSString *)event withScreenshotImage:(NSImage *)screenshot
{
    SDDSchedulerPresenter *presenter = self.presenters[scheduler];
    
    SDDPGHistoryItem *item = [SDDPGHistoryItem new];
    item.shortString   = [NSString stringWithFormat:@"<T> [%@] %@", presenter.rootName, event];
    item.longString    = [NSString stringWithFormat:@"<Transit> [%@]: %@ {%@} -> {%@}",
                                                    presenter.rootName,
                                                    event,
                                                    [self namesFromStates:deactivates],
                                                    [self namesFromStates:activates]];
    item.optioanlImage = screenshot;
    [_historyItems addObject:item];
    
    [self syncUIByAddingItem:item presenterUpdate:^(ViewController *wself) {
        for (NSString *sname in deactivates) {
            [presenter deactivateState:sname];
        }
        
        for (NSString *sname in activates) {
            [presenter activateState:sname];
        }
    }];
}

- (void)peer:(SDDServicePeer *)peer didReceiveEvent:(NSString *)event {
    SDDPGHistoryItem *item = [SDDPGHistoryItem new];
    item.shortString = [NSString stringWithFormat:@"<E> %@", event];
    item.longString  = [NSString stringWithFormat:@"<Event  > %@", event];
    [_historyItems addObject:item];
    
    [self syncUIByAddingItem:item presenterUpdate:NULL];
}

- (void)rebuildStatePresentations {
    _presenters = [NSMutableDictionary dictionary];
    
    NSInteger selectedRow = _historiesTableView.selectedRow;
    SDDPGHistoryItem *selectedItem = selectedRow == -1 ? nil : _filteredHistories[selectedRow];
    
    for (NSInteger i=0; i<_historyItems.count; ++i) {
        SDDPGHistoryItem *item = _historyItems[i];
        void (^update)(ViewController *) = _presenterUpdates[item];
        update(self);

        if (item == selectedItem)
            break;
    }
    
    [self syncTextView];
}

- (void)syncHistoriesTableView {
    dispatch_async(dispatch_get_main_queue(), ^{
        _filteredHistories = [@[] mutableCopy];
        for (NSInteger i=0; i<_historyItems.count; ++i) {
            SDDPGHistoryItem *item = _historyItems[i];
            if (_wantEvents || ![item.shortString hasPrefix:@"<E>"]) {
                [_filteredHistories addObject:item];
            }
        }
        
        NSIndexSet *oldSelection = [_historiesTableView selectedRowIndexes];
        [_historiesTableView reloadData];
        [_historiesTableView selectRowIndexes:oldSelection byExtendingSelection:NO];
    });
}

- (void)syncUIByAddingItem:(SDDPGHistoryItem *)item presenterUpdate:(void (^)(ViewController *))update {
    if (update != NULL) {
        _presenterUpdates[item] = update;
        update(self);
        [self syncTextView];
    } else {
        _presenterUpdates[item] = ^(ViewController *wself) {};
    }
    
    [self syncHistoriesTableView];
}

- (void)syncTextView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.stockMessagesView.textStorage setAttributedString:[[NSAttributedString alloc] init]];
        
        NSArray *sortedPresenters = [_presenters.allValues sortedArrayUsingComparator:^NSComparisonResult(SDDSchedulerPresenter *lhs, SDDSchedulerPresenter *rhs) {
            return [lhs.rootName compare:rhs.rootName];
        }];
        
        for (SDDSchedulerPresenter *presenter in sortedPresenters) {
            NSAttributedString *text = [presenter statesText];
            
            [self.stockMessagesView.textStorage appendAttributedString:text];
            [self.stockMessagesView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
        }
    });
}

- (IBAction)didChangeFilterEValue:(NSButton *)button {
    _wantEvents = button.state == NSOnState;
    [self syncHistoriesTableView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _filteredHistories.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"HistoryCellView" owner:self];
    cellView.textField.stringValue = _filteredHistories[row].shortString;
    
    return cellView;
}

@end
