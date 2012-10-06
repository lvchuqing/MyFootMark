//
//  wayPointAnnotaion.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/3/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "wayPointAnnotaion.h"

@interface wayPointAnnotaion() 
@property (nonatomic, strong)NSString *wayPointTitle;
@property (nonatomic,strong)NSString *wayPointSubtitle;
@end

@implementation wayPointAnnotaion
@synthesize myWaypoint = _myWaypoint;
@synthesize wayPointTitle=_wayPointTitle;
@synthesize wayPointSubtitle = _wayPointSubtitle;

+(wayPointAnnotaion *)annotationForWayPoint:(WayPoint *)waypoint
{
    wayPointAnnotaion * annotation = [[wayPointAnnotaion alloc]init];
    annotation.myWaypoint = waypoint;
    return annotation;
}

-(void)setMyWaypoint:(WayPoint *)myWaypoint
{
    _myWaypoint = myWaypoint;
    NSDate *visitDate = myWaypoint.visitTime;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:visitDate];
    NSString *title = [NSString stringWithFormat:@"%d:%d",[components hour],[components minute]];
    NSString *subtitle = [NSString stringWithFormat:@"%d/%d/%d",[components month],[components day],[components year]];
    self.wayPointSubtitle = subtitle;
    self.wayPointTitle = title;
}

-(NSString *)title{
    return self.wayPointTitle;
}

-(NSString *)subtitle
{
    return self.wayPointSubtitle;
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [self.myWaypoint.latitude doubleValue];
    coordinate.longitude =[self.myWaypoint.longitude doubleValue];
    return coordinate;
}


@end
