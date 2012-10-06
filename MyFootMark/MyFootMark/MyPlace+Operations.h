//
//  MyPlace+Operations.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "MyPlace.h"

@interface MyPlace (Operations)

+(MyPlace *)addMyPlaceWith:(NSDictionary *)newPlace
    inManagedObjectContext:(NSManagedObjectContext *)context;
+(MyPlace *)checkIfPlaceExistWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+(NSArray *)getAllPlacesInManagedObjectContext:(NSManagedObjectContext *)context;
@end
