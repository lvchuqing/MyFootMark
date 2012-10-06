//
//  WayPoint.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface WayPoint : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * altitude;
@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, retain) NSDecimalNumber * horizental_accuracy;
@property (nonatomic, retain) NSDecimalNumber * latitude;
@property (nonatomic, retain) NSDecimalNumber * longitude;
@property (nonatomic, retain) NSDecimalNumber * vertical_accuracy;
@property (nonatomic, retain) NSNumber * visitDay;
@property (nonatomic, retain) NSNumber * visitMonth;
@property (nonatomic, retain) NSDate * visitTime;
@property (nonatomic, retain) NSNumber * visitYear;
@property (nonatomic, retain) NSNumber * wayPoints_ID;

@end
