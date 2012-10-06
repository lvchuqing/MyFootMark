//
//  NearByRestaurantAnnotaion.h
//  GooglePlace
//
//  Created by Chuqing Lu on 6/7/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "GooglePlaceFetcher.h"

@interface NearByRestaurantAnnotaion : NSObject<MKAnnotation>

+(NearByRestaurantAnnotaion *)annotationForRestaurant:(NSDictionary *)restaurant;


-(NSString *)title;
-(NSString *)subtitle;
-(NSString *)iconURL;
- (CLLocationCoordinate2D) coordinate;

@property (strong, nonatomic)NSDictionary *restaurant;


@end
