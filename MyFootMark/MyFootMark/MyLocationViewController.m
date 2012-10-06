//
//  MyLocationViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/3/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "MyLocationViewController.h"
#import <MessageUI/MessageUI.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "Utility.h"
#import <Twitter/Twitter.h>

@interface MyLocationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@end

@implementation MyLocationViewController
@synthesize myWayPoint = _myWayPoint;
@synthesize addressLabel = _addressLabel;



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) 
    {
        [textView resignFirstResponder];
        return FALSE;
    }
    return TRUE;
}



- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {//Address
                    CLLocation *location = [Utility getCurrentLocationWithLatitude:self.myWayPoint.latitude 
                                                                       andLonitude:self.myWayPoint.longitude];
                    call_back_block setUILabel;
                    setUILabel = ^(NSString *addressStr){
                          self.addressLabel.text = addressStr;
                    };
                    [Utility addressForLocation:location withBlock:setUILabel];
                    break;
                }
                case 1:
                {//Time
                    NSString *time = [NSString stringWithFormat:@"%@-%@-%@",self.myWayPoint.visitMonth,self.myWayPoint.visitDay,self.myWayPoint.visitYear];
                    cell.detailTextLabel.text = time;
                    break;
                }
                case 2:
                {//Altitude
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.3f feet",[self.myWayPoint.altitude doubleValue]];
                    break;
                }
                case 3:
                {//Coordinate
                    NSString *longitudeStr = nil;
                    if(self.myWayPoint.longitude>0)longitudeStr=@"N";
                    else longitudeStr = @"S";
                    NSString *latitudeStr = nil;
                    if(self.myWayPoint.latitude>0)latitudeStr=@"E";
                    else latitudeStr = @"W";
                   // NSString 
                    NSString *cor = [NSString stringWithFormat:@"%0.3f°%@  %0.3f°%@",[self.myWayPoint.longitude doubleValue],
                                     longitudeStr,[self.myWayPoint.latitude doubleValue],latitudeStr];
                    cell.detailTextLabel.text = cor;
                    break;
                }
            }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section==1 && indexPath.row ==1){
        NSString* address = self.addressLabel.text;
        NSString* addr = [NSString stringWithFormat:@"http://maps.google.com/maps?daddr=Current Location&saddr=%@",address];
        NSURL* url = [[NSURL alloc] initWithString:[addr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[UIApplication sharedApplication] openURL: url];
    }
}

#pragma mark - sendEmail


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
    if([segue.destinationViewController respondsToSelector:@selector(setMyWayPoint:)]){
        [segue.destinationViewController performSelector:@selector(setMyWayPoint:) withObject:self.myWayPoint];
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    
}

- (void)viewDidUnload {
    [self setAddressLabel:nil];
    [super viewDidUnload];
}
@end
