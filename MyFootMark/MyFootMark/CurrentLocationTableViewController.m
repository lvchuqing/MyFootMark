//
//  CurrentLocationTableViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/7/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "CurrentLocationTableViewController.h"
#import "MainMapViewController.h"
#import "Utility.h"



@interface CurrentLocationTableViewController ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (strong, nonatomic)WayPoint * currentWayPoint;

@end

@implementation CurrentLocationTableViewController
@synthesize addressLabel = _addressLabel;
@synthesize currentWayPoint = _currentWayPoint;


-(void)setCurrentWayPoint:(WayPoint *)currentWayPoint
{
    _currentWayPoint = currentWayPoint;
    [self.tableView reloadData];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {//Address
                    CLLocation *location = [Utility getCurrentLocationWithLatitude:self.currentWayPoint.latitude
                                                                       andLonitude:self.currentWayPoint.longitude];
                    call_back_block setUILabel;
                    setUILabel = ^(NSString *addressStr){
                        self.addressLabel.text = addressStr;
                    };
                    [Utility addressForLocation:location withBlock:setUILabel];
                    break;
                }
                case 1:
                {//Time
                    NSString *time = [NSString stringWithFormat:@"%@-%@-%@",self.currentWayPoint.visitMonth,self.currentWayPoint.visitDay,self.currentWayPoint.visitYear];
                    cell.detailTextLabel.text = time;
                    break;
                }
                case 2:
                {//Altitude
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.3f feet",[self.currentWayPoint.altitude doubleValue]];
                    break;
                }
                case 3:
                {//Coordinate
                    NSString *longitudeStr = nil;
                    if(self.currentWayPoint.longitude>0)longitudeStr=@"N";
                    else longitudeStr = @"S";
                    NSString *latitudeStr = nil;
                    if(self.currentWayPoint.latitude>0)latitudeStr=@"E";
                    else latitudeStr = @"W";
                    // NSString 
                    NSString *cor = [NSString stringWithFormat:@"%0.3f°%@  %0.3f°%@",[self.currentWayPoint.longitude doubleValue],
                                     longitudeStr,[self.currentWayPoint.latitude doubleValue],latitudeStr];
                    cell.detailTextLabel.text = cor;
                    break;
                }
            }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 && indexPath.row == 4){
        [self setAlarmClick];
    }
}


#pragma mark -Set Alarm



- (void) alertView:(UIAlertView *)alertView
   clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Cancel"]) return;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    double time_interval = [textField.text doubleValue]*60*60;
    //This is in the current location table view controller. User must have
    //already in the setting region. So we do not need to set locationManager 
    //monitoring function, just set the specific hour into calender
    CLLocation *location = [Utility getCurrentLocationWithLatitude:self.currentWayPoint.latitude
                                                       andLonitude:self.currentWayPoint.longitude];
    call_back_block getAddressBlock;
    __block NSString *address = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    getAddressBlock = ^(NSString *contentToBeSet){
        address = contentToBeSet;
        dispatch_semaphore_signal(sema);
    };
    [Utility addressForLocation:location withBlock:getAddressBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    NSString *title = @"You shold leave following place:\n";
    title = [title stringByAppendingString:address];
    [self addAlarmToCalendarTimeInterval:time_interval Title:title Notes:nil];

}


#pragma mark send My Location
- (IBAction)sendEmail:(id)sender {
    NSString *title = @"Here is a way point";
    [self sendEmailWithContent:self.addressLabel.text withTitle:title withImage:nil];
}


- (IBAction)sendSMS:(id)sender {
    [self sendSMSWithContent:self.addressLabel.text];
}



- (IBAction)sentTweet:(id)sender {
    [self sendTweetWithContent:self.addressLabel.text withImagePath:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"ShowNearbyRestaurant"]){
        [segue.destinationViewController performSelector:@selector(setCurrentWayPoint:)withObject:self.currentWayPoint];
    }
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)viewDidUnload {
    [self setAddressLabel:nil];
    [super viewDidUnload];
}
@end
