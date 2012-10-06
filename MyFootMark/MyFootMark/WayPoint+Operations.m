//
//  WayPoint+Operations.m
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "WayPoint+Operations.h"

@implementation WayPoint (Operations)

#define EARTH_RADIUS 6371  //km

+(float)distanceOfALatitude:(float)A_latitude ALongitude:(float)A_longitude andBLatitude:(float)B_latitude BLongitude:(float)B_longitude
{

    float result = acosf(sinf(A_latitude)*sinf(B_latitude) + 
                         cosf(A_latitude)*cosf(B_latitude)*cosf(B_longitude-A_longitude));
    result  = result/180 * M_PI * EARTH_RADIUS * 1000; 
    return result;
}


+(float)distanceOfTwoWayPoints:(WayPoint *)A and:(WayPoint *)B
{
    float A_latitude = [A.latitude floatValue];
    float A_longitude = [A.longitude floatValue];
    float B_latitude = [B.latitude floatValue];
    float B_longitude = [B.longitude floatValue];
    return [self distanceOfALatitude:A_latitude ALongitude:A_longitude andBLatitude:B_latitude BLongitude:B_longitude];
}
+(float)distanceOfWayPoint:(WayPoint *)A 
    withACoordinateLatitude:(NSDecimalNumber *)latitude 
               andLongitude:(NSDecimalNumber *)longitude
{
    float A_latitude = [A.latitude floatValue];
    float A_longitude = [A.longitude floatValue];
    float B_latitude = [latitude floatValue];
    float B_longitude = [longitude floatValue];
    return [self distanceOfALatitude:A_latitude ALongitude:A_longitude andBLatitude:B_latitude BLongitude:B_longitude];
}


#define SHORTEST_RECORD_DISTANCE 500
#define SHORTEST_RECORD_TIME_SPAN 60*10
+(WayPoint *)addWayPointWith:(NSDictionary *)newWayPointDict 
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    WayPoint *toAdd = nil;
    
    //We need to check if the nearest waypoint's time and distance are same with the newWayPoint,
    //If there are same, then we donot need to add new waypoint. This may due to user launch
    //app at same place many times in a short time span
    NSArray *allWayPoint = [self getAllWayPointsInManagedObjectContext:context];
    NSDate *newWayPointVisitTime = [newWayPointDict valueForKey:@"date"];
    if([allWayPoint count]){
        WayPoint *nearestWayPoint = (WayPoint *)[allWayPoint objectAtIndex:0];
        NSDate *oldWayPointVisitTime = nearestWayPoint.visitTime;
        if([self distanceOfWayPoint:[allWayPoint objectAtIndex:0] 
            withACoordinateLatitude:[newWayPointDict valueForKey:@"latitude"] 
                       andLongitude:[newWayPointDict valueForKey:@"longitude"]]<SHORTEST_RECORD_DISTANCE && 
           [newWayPointVisitTime timeIntervalSinceDate:oldWayPointVisitTime]<SHORTEST_RECORD_TIME_SPAN)
        {//do nothing
            return nil;
        }
    }//else add the new waypoint to database
    
    toAdd = [NSEntityDescription insertNewObjectForEntityForName:@"WayPoint"
                                          inManagedObjectContext:context];
    toAdd.altitude = [newWayPointDict valueForKey:@"altitude"];
    toAdd.latitude = [newWayPointDict valueForKey:@"latitude"];
    toAdd.longitude = [newWayPointDict valueForKey:@"longitude"];
    toAdd.horizental_accuracy = [newWayPointDict valueForKey:@"horizental_accuracy"];
    toAdd.vertical_accuracy = [newWayPointDict valueForKey:@"vertical_accuracy"];
    toAdd.visitTime = [newWayPointDict valueForKey:@"date"];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:toAdd.visitTime];

    toAdd.visitDay = [NSNumber numberWithInt:[components day]];
    toAdd.visitMonth = [NSNumber numberWithInt:[components month]];
    toAdd.visitYear = [NSNumber numberWithInt:[components year]];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WayPoint"];
    request.sortDescriptors = [NSArray arrayWithObject:
                               [NSSortDescriptor sortDescriptorWithKey:@"visitTime" ascending:NO]];
    
    NSArray *matches = [context executeFetchRequest:request error:nil];
    
    if([matches count]>=2000){//delete the earlist one record
        
    }
    toAdd.wayPoints_ID = [NSNumber numberWithInt:[matches count]];
    
    int times=0;
    for(WayPoint *myWayPoint in matches){
        if([self distanceOfTwoWayPoints:toAdd and:myWayPoint]<1001)times++;
    }
    toAdd.frequency = [NSNumber numberWithInt:times];
    return toAdd;
}

#define DISTANCE_ACCURACY 180
+(MyPlace *)ifWayPointisAPlace:(WayPoint *)wayPoint inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MyPlace"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"placename" ascending:YES]];
    NSArray *matches = [context executeFetchRequest:request error:nil];
    
    for(MyPlace *myPlace in matches){
        WayPoint *temp;
        temp.latitude = myPlace.latitude;
        temp.longitude = myPlace.longitude;
        if([self distanceOfTwoWayPoints:wayPoint and:temp]<DISTANCE_ACCURACY)
        {
            return myPlace;
        }
    }
    return nil;
}

+ (NSArray *)numberOfDifferentDaysInDBinManagedObjectContext:(NSManagedObjectContext *)context
{
    NSArray *matches = [self getAllWayPointsInManagedObjectContext:context];
    int count = 0;
    int previousDay = 0;
    int previousMonth = 0;
    int previousYear = 0;
    NSMutableArray *allDaysRecord = [NSMutableArray array];
    for(WayPoint *waypoint in matches)
    {
        if(previousDay==[waypoint.visitDay intValue]&&
           previousMonth==[waypoint.visitMonth intValue]&&
           previousYear==[waypoint.visitYear intValue]){
            //same day do nothing
        }else{
            count++;
            previousDay = [waypoint.visitDay intValue];
            previousMonth=[waypoint.visitMonth intValue];
            previousYear=[waypoint.visitYear intValue];
            NSString *display = [NSString stringWithFormat:@"%d/%d/%d",previousMonth,previousDay,previousYear];
            [allDaysRecord addObject:display];
        }
    }
    return allDaysRecord;
}

+ (NSFetchRequest *)myRequestForDateString:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSArray *token = [dateString componentsSeparatedByString: @"/"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WayPoint"];
    request.predicate = [NSPredicate predicateWithFormat:@"visitDay = %@ AND visitMonth = %@ AND visitYear = %@",[token objectAtIndex:1],[token objectAtIndex:0],[token objectAtIndex:2]];
    
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"visitTime" ascending:NO]];
    return request;
    
}


+(int)numberOfWayPointsinDay:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [WayPoint myRequestForDateString:dateString inManagedObjectContext:context];
    int matches = [context countForFetchRequest:request error:NULL];
    return matches;
}

+(NSArray *)wayPointsInDay:(NSString *)dateString inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [WayPoint myRequestForDateString:dateString inManagedObjectContext:context];
    NSArray *matches = [context executeFetchRequest:request error:NULL];
    return matches;
    
}

+(NSArray *)getAllWayPointsInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"WayPoint"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"visitTime" ascending:NO]];
    NSArray *matches = [context executeFetchRequest:request error:nil];
    return matches;
}

@end
