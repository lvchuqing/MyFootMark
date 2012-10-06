//
//  WayPoint+Operations.h
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "WayPoint.h"
#import "MyPlace.h"
#import <CoreData/CoreData.h>

@interface WayPoint (Operations)

+(WayPoint *)addWayPointWith:(NSDictionary *)newWayPointDict
      inManagedObjectContext:(NSManagedObjectContext *)context;
+(NSArray *)getAllWayPointsInManagedObjectContext:(NSManagedObjectContext *)context;

+(MyPlace *)ifWayPointisAPlace:(WayPoint *)wayPoint
        inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)numberOfDifferentDaysInDBinManagedObjectContext:(NSManagedObjectContext *)context;
+(NSArray *)wayPointsInDay:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context;
+(int)numberOfWayPointsinDay:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context;


//Three method to calculate the distance of two waypoints
+(float)distanceOfTwoWayPoints:(WayPoint *)A and:(WayPoint *)B;

+(float)distanceOfWayPoint:(WayPoint *)A 
    withACoordinateLatitude:(NSDecimalNumber *)latitude 
               andLongitude:(NSDecimalNumber *)longitude;

+(float)distanceOfALatitude:(float)ALatitude 
                 ALongitude:(float)ALongitude
                andBLatitude:(float)BLatitude
                  BLongitude:(float)BLongitude;
@end
