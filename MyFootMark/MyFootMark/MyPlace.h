//
//  MyPlace.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MyPlace : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * altitude;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSDecimalNumber * latitude;
@property (nonatomic, retain) NSDecimalNumber * longitude;
@property (nonatomic, retain) NSString * placename;
@property (nonatomic, retain) NSString * address;

@end
