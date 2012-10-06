//
//  NearByRestaurantAnnotaion.m
//  GooglePlace
//
//  Created by Chuqing Lu on 6/7/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "NearByRestaurantAnnotaion.h"
@interface NearByRestaurantAnnotaion()

@end


@implementation NearByRestaurantAnnotaion
@synthesize restaurant = _restaurant;

+(NearByRestaurantAnnotaion *)annotationForRestaurant:(NSDictionary *)restaurant
{
    NearByRestaurantAnnotaion *annotation = [[NearByRestaurantAnnotaion alloc] init];
    annotation.restaurant = restaurant;
    return annotation;
}

#pragma mark -MKAnnotation

- (NSString *)title
{
    return [self.restaurant objectForKey:PLACE_NAME];
}

-(NSString *)subtitle
{
    return [self.restaurant objectForKey:PLACE_VICINITY];
}

-(NSString *)iconURL
{
    return [self.restaurant objectForKey:PLACE_ICON_URL];

}
-(CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[self.restaurant valueForKeyPath:PLACE_LATITUDE] floatValue];
    coordinate.longitude =[[self.restaurant valueForKeyPath:PLACE_LONGITUDE] floatValue];
    return coordinate;
}


@end
