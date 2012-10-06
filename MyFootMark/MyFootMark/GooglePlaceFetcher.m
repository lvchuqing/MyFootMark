//
//  GooglePlaceFetcher.m
//  GooglePlace
//
//  Created by Chuqing Lu on 6/7/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "GooglePlaceFetcher.h"

@implementation GooglePlaceFetcher

+ (NSDictionary *)performQuery:(NSString *)query{
    NSString *queryStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?%@&sensor=true&key=%@",query,GOOGLE_API_KEY];
    queryStr = [queryStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //NSLog(@"[%@ %@] sent %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), query);
    NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:queryStr] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
    NSLog(@"[%@ %@] received %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), results);
    return results;
}

+ (NSArray *)getNearByRestaurantAtLatitude:(float)latitude andLongitude:(float)longitude
{
    NSString *request = [NSString stringWithFormat:@"location=%f,%f&radius=500&types=food",latitude,longitude];
    NSArray *allPlacesArr = [[GooglePlaceFetcher performQuery:request] objectForKey:PLACE_RESULTS];
    return allPlacesArr;
    
}

+ (NSDictionary *)getSpecificRestaurantInfo:(NSString *)reference
{
    NSString *request = [NSString stringWithFormat:@"reference=%@",reference];
    NSDictionary *placeInfo = [[GooglePlaceFetcher performQuery:request] objectForKey:SPECIFIC_PLACE_RESULT];
    return placeInfo;
}

@end
