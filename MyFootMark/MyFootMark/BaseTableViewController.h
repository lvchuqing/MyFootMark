//
//  BaseTableViewController.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Utility.h"
#import "WayPoint.h"


@interface BaseTableViewController : UITableViewController


- (void)sendSMSWithContent:(NSString *)content;
- (void)sendTweetWithContent:(NSString *)content withImagePath:(NSString *)path;
- (void)sendEmailWithContent:(NSString *)content withTitle:(NSString *)title withImage:(UIImage *)image;
-(void)setAlarmClick;
- (void)addAlarmToCalendarTimeInterval:(double)time_interval 
                                 Title:(NSString *)title Notes:(NSString *)notes;
@end
