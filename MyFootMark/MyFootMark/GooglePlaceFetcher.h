//
//  GooglePlaceFetcher.h
//  GooglePlace
//
//  Created by Chuqing Lu on 6/7/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GooglePlaceFetcher : NSObject

#define GOOGLE_API_KEY @"AIzaSyAkU26qsccXeJXOEJktfiWK14b7L-HWtSI"
#define PLACE_RESULTS @"results"
#define SPECIFIC_PLACE_RESULT @"result"
#define PLACE_NAME @"name"
#define PLACE_VICINITY @"vicinity"
#define PLACE_LATITUDE @"geometry.location.lat"
#define PLACE_LONGITUDE @"geometry.location.lng"
#define PLACE_REFERENCE @"reference"
#define PLACE_ICON_URL @"icon"

+ (NSArray *)getNearByRestaurantAtLatitude:(float)latitude andLongitude:(float)longitude;


@end
