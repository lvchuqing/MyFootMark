//
//  NearbyRestaurantMapViewController.m
//  MyFootMark
//  This class use google place API to show nearby restaurant 
//  of current location
//
//  Created by Chuqing Lu on 6/8/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "NearbyRestaurantMapViewController.h"
#import "NearByRestaurantAnnotaion.h"
#import "GooglePlaceFetcher.h"
#import "WayPoint.h"

@interface NearbyRestaurantMapViewController ()<MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic)NSArray *restaurantAnnotations;
@property (strong, nonatomic)WayPoint *currentWayPoint;
@end

@implementation NearbyRestaurantMapViewController
@synthesize mapView = _mapView;
@synthesize restaurantAnnotations = _restaurantAnnotations;
@synthesize currentWayPoint = _currentWayPoint;

- (void)setRegion
{
    //calculate new region to show on map
    double center_long = 0.0f;
    double center_lat = 0.0f;
    double max_long = [[self.restaurantAnnotations lastObject] coordinate].longitude;
    double min_long = [[self.restaurantAnnotations lastObject] coordinate].longitude;
    double max_lat = [[self.restaurantAnnotations lastObject] coordinate].latitude;
    double min_lat = [[self.restaurantAnnotations lastObject] coordinate].latitude;
    for(NearByRestaurantAnnotaion *restaurant in self.restaurantAnnotations)
    {
        double photoLatitude = [restaurant coordinate].latitude;
        double photoLongitude = [restaurant coordinate].longitude;
        if(photoLatitude>max_lat)max_lat = photoLatitude;
        else if(photoLatitude<min_lat)min_lat = photoLatitude;
        if(photoLongitude>max_long)max_long = photoLongitude;
        else if(photoLongitude<min_long)min_long = photoLongitude;
    }
    
    center_lat = (min_lat+max_lat)/2;
    center_long = (min_long+max_long)/2;
    CLLocationCoordinate2D center;
    center.latitude = center_lat;
    center.longitude = center_long;
    MKCoordinateSpan span;
    span.latitudeDelta = (max_lat-min_lat);
    span.longitudeDelta = (max_long-min_long);
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    self.mapView.zoomEnabled = YES;
    [self.mapView setRegion:region];
    
}


-(void)updateMapView
{
    if(self.mapView.annotations)[self.mapView removeAnnotations:self.mapView.annotations];
    if(self.restaurantAnnotations)[self.mapView addAnnotations:self.restaurantAnnotations];
}

-(void)setRestaurantAnnotations:(NSArray *)restaurantAnnotations
{
    _restaurantAnnotations = restaurantAnnotations;
    [self updateMapView];
}


-(void)setAnnotation
{
    float latitude = [self.currentWayPoint.latitude floatValue];
    float longitude = [self.currentWayPoint.longitude floatValue];
    NSArray *allPlaces = [GooglePlaceFetcher getNearByRestaurantAtLatitude:latitude andLongitude:longitude];
    NSMutableArray *annotations = [NSMutableArray array];
    for(NSDictionary *place in allPlaces){
        
        NearByRestaurantAnnotaion *placeAnnotation = [NearByRestaurantAnnotaion annotationForRestaurant:place];
        [annotations addObject:placeAnnotation];
    }
    self.restaurantAnnotations = annotations;
    [self setRegion];
    
}
#define MAP_VIEW_ANNOTATION @"MapViewAnnotation"
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView * aView = [mapView dequeueReusableAnnotationViewWithIdentifier:MAP_VIEW_ANNOTATION];
    if(!aView){
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MAP_VIEW_ANNOTATION];
        aView.canShowCallout = YES;
        if([annotation isKindOfClass:[NearByRestaurantAnnotaion class]]){
            aView.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            [(UIImageView *)aView.leftCalloutAccessoryView setImage:nil];
            //use multithread to display the image
            dispatch_queue_t fetchQueue = dispatch_queue_create("place photo fetch queue", NULL);
            dispatch_async(fetchQueue, ^{
                NearByRestaurantAnnotaion *placeAnno = (NearByRestaurantAnnotaion *)annotation;
                NSString *URLStr = [placeAnno iconURL];
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URLStr]];
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(UIImageView *)aView.leftCalloutAccessoryView setImage:image];
                });
            });
            dispatch_release(fetchQueue);
        }
    }
    aView.annotation = annotation;
    return aView;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //if(self.mapView.window)
    self.mapView.delegate = self;
    [self setAnnotation];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [super viewDidUnload];
}
@end

