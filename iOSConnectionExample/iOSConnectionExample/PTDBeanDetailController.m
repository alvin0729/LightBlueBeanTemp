//
//  PTDBeanDetailController.m
//  Bean Loader
//
//  Created by Matthew Chung on 4/24/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import "PTDBeanDetailController.h"
#import "PTDBeanHeaderCell.h"
#import "PTDBeanRadioConfig.h"

@interface PTDBeanDetailController () <PTDBeanManagerDelegate, PTDBeanDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PTDBeanDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    titleView.contentMode = UIViewContentModeScaleAspectFit;
    titleView.frame = CGRectMake(0, 0, 44, 44);
    self.navigationItem.titleView = titleView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
}

- (void)update {
    if (self.bean.state == BeanState_Discovered) {
        self.connectButton.title = @"Connect";
        self.connectButton.enabled = YES;
    }
    else if (self.bean.state == BeanState_ConnectedAndValidated) {
        self.connectButton.title = @"Disconnect";
        self.connectButton.enabled = YES;
    }
    [self.tableView reloadData];
}

#pragma mark - BeanManagerDelegate Callbacks

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
}

- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    [self update];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    if (bean == self.bean) {
        [self update];
    }
}

#pragma mark BeanDelegate

-(void)bean:(PTDBean*)device error:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}

#pragma mark IBActions

- (IBAction)connectButtonPressed:(id)sender {
    if (self.bean.state == BeanState_Discovered) {
        self.bean.delegate = self;
        [self.beanManager connectToBean:self.bean error:nil];
        self.beanManager.delegate = self;
        self.connectButton.enabled = NO;
    }
    else {
        self.bean.delegate = self;
        [self.beanManager disconnectBean:self.bean error:nil];
    }
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

static NSString *CellIdentifier = @"BeanListCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PTDBeanHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell.bean = self.bean;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    return nil;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Bean";
}

- (void)dealloc {
    self.bean.delegate = nil;
}

@end
