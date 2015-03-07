//
//  PTDView.m
//  MacExample
//
//  Created by Matthew Chung on 5/2/14.
//  Copyright (c) 2014 Punch Through Designs. All rights reserved.
//

#import <PTDBeanManager.h>
#import "PTDView.h"
#import "PTDBeanRadioConfig.h"

#define SCAN_DURATION 30.0f

@interface PTDView () <NSMenuDelegate, NSTableViewDelegate, NSTableViewDataSource, PTDBeanManagerDelegate, PTDBeanDelegate> {
}

@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSMutableDictionary *beans;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSMenu *beanMenu;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *scanningIndicator;
@property (nonatomic, strong) NSTimer * scanningTimer;
@end

@implementation PTDView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.beans = [NSMutableDictionary dictionary];
        self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.tableView setDoubleAction:@selector(doubleClicked:)];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

-(void)appWillTerminate:(NSNotification*)noti {
    [self stopScanning];
    for (NSUUID* beanid in self.beans) {
        PTDBean* bean = [self.beans objectForKey:beanid];
        [self.beanManager disconnectBean:bean error:nil];
    }
}

#pragma mark - BeanManagerDelegate Callbacks

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        [self startScanning];
    }
    else if (self.beanManager.state == BeanManagerState_PoweredOff) {
        NSAlert *alertView = [NSAlert alertWithMessageText:@"Turn on bluetooth to continue" defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alertView runModal];
    }
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    NSUUID * key = bean.identifier;
    if (![self.beans objectForKey:key]) {
        // New bean
        NSLog(@"BeanManager:didDiscoverBean:error %@", bean);
        [self.beans setObject:bean forKey:key];
    }
    [self.tableView reloadData];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    [self.tableView reloadData];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    [self.tableView reloadData];
}

#pragma mark - Private functions

-(PTDBean*)beanForRow:(NSInteger)row{
    return [self.beans.allValues objectAtIndex:row];
}

-(void)startScanning{
    [self.scanningIndicator setHidden:FALSE];
    [self.beanManager startScanningForBeans_error:nil];
    self.scanningTimer = [NSTimer scheduledTimerWithTimeInterval:SCAN_DURATION target:self selector:@selector(stopScanning) userInfo:nil repeats:NO];
    [self.scanningIndicator startAnimation:self];
}

-(void)stopScanning{
    [self.scanningIndicator setHidden:TRUE];
    [self.beanManager stopScanningForBeans_error:nil];
    if(self.scanningTimer) {
        [self.scanningTimer invalidate];
        self.scanningTimer = nil;
    }
}

- (IBAction)RefreshBeanList:(id)sender{
    [self stopScanning];
    self.beans = [NSMutableDictionary dictionary];
    [self.tableView reloadData];
    [self startScanning];
}

- (void)doubleClicked:(id)sender {
    NSInteger row = [self.tableView clickedRow];
    PTDBean* bean = [self beanForRow:row];
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.representedObject = bean;
    if(bean.state == BeanState_Discovered){
        [self connectBean:item];
    }else if(bean.state == BeanState_ConnectedAndValidated){
        [self disconnectBean:item];
    }
}

#pragma mark - BeanDelegate Callbacks
-(void)bean:(PTDBean*)device error:(NSError*)error {
    NSAlert *alertView = [NSAlert alertWithMessageText:[error localizedDescription] defaultButton:@"Ok" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [alertView runModal];
}

-(void)bean:(PTDBean*)device receivedMessage:(NSData*)data {
}

-(void)bean:(PTDBean*)device didProgramArduinoWithError:(NSError*)error {
}

#pragma mark NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}
// just returns the item for the right row
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    PTDBean * bean = [self.beans.allValues objectAtIndex:row];
    
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [tableColumn identifier];
    
    if ([identifier isEqualToString:@"Bean_Name"]) {
        // We pass us as the owner so we can setup target/actions into this main controller object
        NSTableCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        // Then setup properties on the cellView based on the column
        cellView.textField.stringValue = bean.name;
        // cellView.imageView.objectValue = [dictionary objectForKey:@"Image"];7
        return cellView;
    }else if ([identifier isEqualToString:@"Bean_RSSI"]) {
        // We pass us as the owner so we can setup target/actions into this main controller object
        NSTableCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        // Then setup properties on the cellView based on the column
        cellView.textField.stringValue = [NSString stringWithFormat:@"%li", bean.RSSI.longValue];
        // cellView.imageView.objectValue = [dictionary objectForKey:@"Image"];7
        return cellView;
    }else if ([identifier isEqualToString:@"Bean_Status"]) {
        // We pass us as the owner so we can setup target/actions into this main controller object
        NSTableCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        // Then setup properties on the cellView based on the column
        NSString* state;
        switch (bean.state) {
            case BeanState_Unknown:
                state = @"Unknown";
                break;
            case BeanState_Discovered:
                state = @"Disconnected";
                break;
            case BeanState_AttemptingConnection:
                state = @"Connecting...";
                break;
            case BeanState_AttemptingValidation:
                state = @"Connecting...";
                break;
            case BeanState_ConnectedAndValidated:
                state = @"Connected";
                break;
            case BeanState_AttemptingDisconnection:
                state = @"Disconnecting...";
                break;
            default:
                state = @"Invalid";
                break;
        }
        
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@", state];
        // cellView.imageView.objectValue = [dictionary objectForKey:@"Image"];7
        return cellView;
    }
    else {
        NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
    }
    return nil;
    
}

// just returns the number of items we have.
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.beans.count;
}

#pragma mark - tableview menu delegates

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSInteger clickedrow = [_tableView clickedRow];
    NSInteger clickedcol = [_tableView clickedColumn];
    
    if (clickedrow > -1 && clickedcol > -1 && clickedrow < self.beans.allValues.count) {
        //construct a menu based on column and row
        NSMenu *newmenu = [self constructMenuForRow:clickedrow andColumn:clickedcol];
        
        //strip all the existing stuff
        [menu removeAllItems];
        
        //then repopulate with the menu that you just created
        for(NSMenuItem *item in [newmenu itemArray]){
            [newmenu removeItem:item];
            [item setRepresentedObject:[self beanForRow:clickedrow]];
            [menu addItem:item];
        }
    }else{
        //strip all the existing stuff
        [menu removeAllItems];
    }
}

-(NSMenu *)constructMenuForRow:(NSInteger)row andColumn:(NSInteger)col{
    NSMenu *contextMenu = [[NSMenu alloc] initWithTitle:@"Context"];
    
    NSMenuItem *item;
    PTDBean* bean = [self beanForRow:row];
    
    if(bean.state == BeanState_Discovered){
        item = [[NSMenuItem alloc] initWithTitle:@"Connect" action:@selector(connectBean:) keyEquivalent:@""];
        [contextMenu addItem:item];
    }else if(bean.state == BeanState_ConnectedAndValidated){
        item = [[NSMenuItem alloc] initWithTitle:@"Disconnect" action:@selector(disconnectBean:) keyEquivalent:@""];
        [contextMenu addItem:item];
    }
    return contextMenu;
}


#pragma mark - Menu actions

-(void)connectBean:(id)sender{
    PTDBean* bean = [sender representedObject];
    bean.delegate = self;
    [self.beanManager connectToBean:bean error:nil];
    [self.tableView reloadData];
}

-(void)disconnectBean:(id)sender{
    PTDBean* bean = [sender representedObject];
    bean.delegate = self;
    [self.beanManager disconnectBean:bean error:nil];
    [self.tableView reloadData];
}

@end
