//
//  Utility.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "Utility.h"


@implementation Utility

static CLGeocoder *geoCoder = nil;

+(CLLocation *)getCurrentLocationWithLatitude:(NSNumber *)latitude
                                          andLonitude:(NSNumber *)longitude
{
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
    return location;
    
}


+(CLGeocoder *)initGeoCoder
{
    geoCoder=[[CLGeocoder alloc] init];
    
    //Only one geocoding instance per action 
    //so stop any previous geocoding actions before starting this one
    if([geoCoder isGeocoding])
        [geoCoder cancelGeocode];
    return geoCoder;
    
}


+ (void)addressForLocation:(CLLocation *)location withBlock:(call_back_block)block{
    if(!geoCoder)[Utility initGeoCoder];
    [geoCoder reverseGeocodeLocation: location 
                        completionHandler:^(NSArray *placemarks, NSError *error){
                            NSString * addressStr = nil;
                            if([placemarks count]>0){
                                CLPlacemark *foundPlacemark=[placemarks objectAtIndex:0];
                                addressStr = [[foundPlacemark.description componentsSeparatedByString:@"@"] objectAtIndex:0];
                            }else if(error.code==kCLErrorGeocodeCanceled){
                                addressStr = @"Geocoding cancelled";
                            }else if(error.code==kCLErrorGeocodeFoundNoResult){
                                addressStr = @"No geocode result found";
                            }else if(error.code==kCLErrorGeocodeFoundPartialResult){
                                addressStr = @"Partial geocode result";
                            }else{
                                NSLog(@"%@", error.description);
                                addressStr = @"Error!";
                            }
                        block(addressStr);
                        }];
}

+ (UIImage*)imageWithImage:(UIImage*)image 
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
