//
//  MainMapViewController.h
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/1/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import "CoreDataHelper.h"

@interface MainMapViewController : UIViewController

+ (void)performBlock:(compeltion_block_t)block;
+(void)saveManagedDocument;
+ (CLLocationManager *)getLocationManager;
+ (NSMutableDictionary *)getAlarmDictionary;
@end
