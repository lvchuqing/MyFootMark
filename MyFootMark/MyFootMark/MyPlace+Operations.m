//
//  MyPlace+Operations.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "MyPlace+Operations.h"

@implementation MyPlace (Operations)

+(MyPlace *)checkIfPlaceExistWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MyPlace"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"placename" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *result = [context executeFetchRequest:request error:nil];
    for(MyPlace *place in result){
        if([place.placename isEqualToString:name])return place;
    }
    return nil;
}

+(MyPlace *)addMyPlaceWith:(NSDictionary *)newPlace inManagedObjectContext:(NSManagedObjectContext *)context
{
    //By default, we do not allow two places have same place name. And we assume user know this. So if two places
    //have same name, first, the app will notify user and if user insist add the new place, then the new one will replace older one.
    //check if place name is unique..

    MyPlace *toAdd = [self checkIfPlaceExistWithName:[newPlace valueForKey:@"placeName"] inManagedObjectContext:context];
    if(!toAdd){
        toAdd = [NSEntityDescription insertNewObjectForEntityForName:@"MyPlace" inManagedObjectContext:context];
    }
    toAdd.imageData = [newPlace valueForKey:@"imageData"];
    toAdd.latitude = [newPlace valueForKey:@"latitude"];
    toAdd.longitude = [newPlace valueForKey:@"longitude"];
    toAdd.altitude = [newPlace valueForKey:@"altitude"];
    toAdd.address = [newPlace valueForKey:@"address"];
    toAdd.placename = [newPlace valueForKey:@"placeName"];
    return toAdd;
    
}

+(NSArray *)getAllPlacesInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"MyPlace"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"placename" ascending:YES]];
    NSArray *result = [context executeFetchRequest:request error:nil];
    return result;
}


@end
