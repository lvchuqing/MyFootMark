//
//  Utility.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Utility : NSObject

typedef void (^call_back_block) (NSString *contentToBeSet);
+ (void)addressForLocation:(CLLocation *)location withBlock:(call_back_block)block;
+ (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize;
+(CLLocation *)getCurrentLocationWithLatitude:(NSNumber *)latitude
                                  andLonitude:(NSNumber *)longitude;
@end
