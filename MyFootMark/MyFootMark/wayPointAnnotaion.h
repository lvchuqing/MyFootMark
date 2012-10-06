//
//  wayPointAnnotaion.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/3/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapKit/MapKit.h"
#import "WayPoint.h"

@interface wayPointAnnotaion : NSObject<MKAnnotation>

+ (wayPointAnnotaion *)annotationForWayPoint: (WayPoint *)waypoint;
- (NSString *)title;
- (NSString *)subtitle;
- (CLLocationCoordinate2D)coordinate;

@property (nonatomic, strong)WayPoint *myWaypoint;



@end
