//
//  MyAnnotation.m
//  Chapter4Recipe1

#import "MyAnnotation.h"

@implementation MyAnnotation

@synthesize coordinate, title, subtitle;

-(id) initWithCoordinate:(CLLocationCoordinate2D) aCoordinate
{
    self=[super init];
    if (self){
        coordinate = aCoordinate;
    }
    return self;
}

@end
