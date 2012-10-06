//
//  MainMapViewController.m
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/1/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "MainMapViewController.h"
#import "WayPoint+Operations.h"
#import "wayPointAnnotaion.h"
#import "wayPointsSummaryTableViewController.h"
#import "MyAnnotation.h"
#import "MyLocationViewController.h"
#import <EventKit/EventKit.h>
#import "MyPlace+Operations.h"

/**************************
 *The main mapview has three sub view on it. Two of them are UIView.
 *One is a setting view shows on the right of the screen and the second
 *is a maptype view show in the head of the screen. And another is
 *a wayPointsSummaryTableView. 
 **************************/


@interface MainMapViewController () <MKMapViewDelegate,CLLocationManagerDelegate>
@property (nonatomic, strong) NSMetadataQuery *iCloudQuery;
@property (strong, nonatomic) wayPointsSummaryTableViewController *myViewController;
@property (strong, nonatomic)UIImageView *settingView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic)UIImageView *mapTypeView;
@property (nonatomic,strong)NSArray *annotations;
@end

@implementation MainMapViewController

@synthesize iCloudQuery = _iCloudQuery;
@synthesize myViewController = _myViewController;
@synthesize settingView = _settingView;
@synthesize mapView = _mapView;
@synthesize annotations = _annotations;
@synthesize mapTypeView = _mapTypeView;

static UIManagedDocument *dataBaseManager = nil;
static CLLocationManager *locationManager;
static NSMutableDictionary *alarmDictionary;



+ (void)performBlock:(compeltion_block_t)block
{
    [CoreDataHelper useSharedMangedDocument:dataBaseManager toExecuteBlock:block];
}

//This alarm dictionary save all times user set for each place.
//If user set a alarm for a waypoint. Once user enter in the area of
//this waypoint it will traverse the array find the time set by user
//and init an alarm
+ (NSMutableDictionary *)getAlarmDictionary
{
    if(!alarmDictionary)alarmDictionary = [NSMutableDictionary dictionary];
    return alarmDictionary;
}

//There is only one LocationManager instance in the whole project
+ (CLLocationManager *)getLocationManager
{
    if(!locationManager)NSLog(@"LocationManager have not been initialized yet");
    return locationManager; 
}

- (void)setUplocationManager
{
    if(!locationManager){
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy =kCLLocationAccuracyBest;
        locationManager.distanceFilter = 500;
        [locationManager startUpdatingLocation];
    }
}



#pragma mark- Map Annotation operation

-(void)updateMapView{
    if(self.mapView.annotations)[self.mapView removeAnnotations:self.mapView.annotations];
    if(self.annotations){
       [self setRegion];
       [self.mapView addAnnotations:self.annotations];
    }
}

-(void)setAnnotations:(NSArray *)annotations
{
    _annotations = annotations;
    [self updateMapView];
}

//Set the region of the map
- (void)setRegion
{
    //calculate new region to show on map
    double center_long = 0.0f;
    double center_lat = 0.0f;
    double max_long = [[self.annotations lastObject] coordinate].longitude;
    double min_long = [[self.annotations lastObject] coordinate].longitude;
    double max_lat = [[self.annotations lastObject] coordinate].latitude;
    double min_lat = [[self.annotations lastObject] coordinate].latitude;
    for(id photo in self.annotations)
    {
        double photoLatitude = [photo coordinate].latitude;
        double photoLongitude = [photo coordinate].longitude;
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

#pragma mark - MKMapViewDelegate
#define MAP_VIEW_ANNOTATION @"MapViewAnnotation"

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView * aView = [mapView dequeueReusableAnnotationViewWithIdentifier:MAP_VIEW_ANNOTATION];
    if(!aView){
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MAP_VIEW_ANNOTATION];
        aView.canShowCallout = YES;
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    aView.annotation = annotation;
    return aView;
    
}


- (void)mapView:(MKMapView *)sender annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    wayPointAnnotaion *ann = view.annotation;
    [self performSegueWithIdentifier:@"ShowWayPoint" sender:ann.myWaypoint];
}

    



#pragma mark - MapViewAnnotations

-(void)upDateAnnotations
{
    self.mapView.delegate = self;
    NSMutableArray * myAnnotations = [[NSMutableArray alloc] init];
    
    __block NSMutableArray *allWayPoints;

    dispatch_queue_t downloadQueue = dispatch_queue_create("updateAnnotation", NULL);
    dispatch_async(downloadQueue, ^{
        compeltion_block_t getAllDataBlock;
        getAllDataBlock = ^(UIManagedDocument *context){
            allWayPoints = [[WayPoint getAllWayPointsInManagedObjectContext:context.managedObjectContext] mutableCopy];
        };
        [CoreDataHelper useSharedMangedDocument:dataBaseManager toExecuteBlock:getAllDataBlock];
        dispatch_async(dispatch_get_main_queue(),^{
            for(WayPoint *myWayPoint in allWayPoints)
            {
                [myAnnotations addObject:[wayPointAnnotaion annotationForWayPoint:myWayPoint]];
            }
            self.annotations = myAnnotations;
            
        });
    });
}



#pragma mark -database content operation:add observer, update data

-(NSURL *)documentURL
{
    return [[[NSFileManager defaultManager]URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]lastObject];
}

//function that observe the change of the content of UIManagedDocumnt
- (void)setDataBaseManagerWithURL:(NSURL *)url
{
 
    
    if(!dataBaseManager || [[dataBaseManager.fileURL absoluteString] isEqualToString:[url absoluteString]]){
        UIManagedDocument *newManager = [[UIManagedDocument alloc] initWithFileURL:url];
        
        //add observe for newManager
        [[NSNotificationCenter defaultCenter] removeObserver:self  // remove observing of old document (if any)
                                                        name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                      object:dataBaseManager.managedObjectContext.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] removeObserver:self  // remove observing of old document (if any)
                                                        name:UIDocumentStateChangedNotification
                                                      object:dataBaseManager];
        dataBaseManager=newManager;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentContentsChanged:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:dataBaseManager.managedObjectContext.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentStateChanged:)
                                                     name:UIDocumentStateChangedNotification
                                                   object:dataBaseManager];
    }
}

+(void)saveManagedDocument
{
    [dataBaseManager saveToURL:dataBaseManager.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:nil];
}

//Then the state of UIManagedDocumnt changed, it will update the annotations
- (void)documentContentsChanged:(NSNotification *)notification
{
    [dataBaseManager.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    //map annotation changed, tableview changed
    [self upDateAnnotations];
    
}


- (void)documentStateChanged:(NSNotification *)notification
{
    if (dataBaseManager.documentState & UIDocumentStateInConflict) {
        // you do nothing and take latest version
        NSArray *conflictingVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:dataBaseManager.fileURL];
        for (NSFileVersion *version in conflictingVersions) {
            version.resolved = YES;
        }
        //remove the old version files in a separate thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSError *error;
            [coordinator coordinateWritingItemAtURL:dataBaseManager.fileURL options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL *newURL) {
                [NSFileVersion removeOtherVersionsOfItemAtURL:dataBaseManager.fileURL error:NULL];
            }];
            if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription, error.localizedFailureReason);
        });
    } else if (dataBaseManager.documentState & UIDocumentStateSavingError) {
        [MainMapViewController saveManagedDocument];
    }
}



#pragma mark -iCloudQuery operation addObserve, updateData
//function observe the change of iCloudQuery
- (NSMetadataQuery *)iCloudQuery
{
    if (!_iCloudQuery) {
        _iCloudQuery = [[NSMetadataQuery alloc] init];
        _iCloudQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope];
        _iCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K like '*'", NSMetadataItemFSNameKey];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processCloudQueryResults:)
                                                     name:NSMetadataQueryDidFinishGatheringNotification
                                                   object:_iCloudQuery];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processCloudQueryResults:)
                                                     name:NSMetadataQueryDidUpdateNotification
                                                   object:_iCloudQuery];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ubiquitousKeyValueStoreChanged:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:[NSUbiquitousKeyValueStore defaultStore]];
        
    }
    return _iCloudQuery;
}


- (NSURL *)iCloudURL
{
    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}

- (NSURL *)iCloudDocumentsURL
{
    return [[self iCloudURL] URLByAppendingPathComponent:@"Documents"];
}

- (NSURL *)filePackageURLForCloudURL:(NSURL *)url
{
    if ([[url path] hasPrefix:[[self iCloudDocumentsURL] path]]) {
        NSArray *iCloudDocumentsURLComponents = [[self iCloudDocumentsURL] pathComponents];
        NSArray *urlComponents = [url pathComponents];
        if ([iCloudDocumentsURLComponents count] < [urlComponents count]) {
            urlComponents = [urlComponents subarrayWithRange:NSMakeRange(0, [iCloudDocumentsURLComponents count]+1)];
            url = [NSURL fileURLWithPathComponents:urlComponents];
        }
    }
    return url;
}


- (NSURL *)iCloudCoreDataLogFilesURL
{
    return [[self iCloudURL] URLByAppendingPathComponent:@"CoreData"];
}

- (void)setPersistentStoreOptionsInDocument:(UIManagedDocument *)document
{

    NSURL *metadataURL = [document.fileURL URLByAppendingPathComponent:@"DocumentMetadata.plist"];
    NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithContentsOfURL:metadataURL];
    
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
    
    NSString *contentName = nil; 
    NSURL *contentURL = nil;
    if(!options ||![options valueForKey:NSPersistentStoreUbiquitousContentNameKey])
    {
        contentName = [document.fileURL lastPathComponent];
    }else{
        contentName = [options valueForKey:NSPersistentStoreUbiquitousContentNameKey];
    }
    
    if(!options || ![options valueForKey:NSPersistentStoreUbiquitousContentURLKey])
    {
        contentURL = [self iCloudCoreDataLogFilesURL];
    }else{
        contentURL = [options valueForKey:NSPersistentStoreUbiquitousContentURLKey];
    }
    [options setObject:contentName forKey:NSPersistentStoreUbiquitousContentNameKey];
    [options setObject:contentURL forKey:NSPersistentStoreUbiquitousContentURLKey];
    
    document.persistentStoreOptions = options;
}


#define DEFAULTDATABASENAME @"Track FootPrints"
- (void)processCloudQueryResults:(NSNotification *)notification
{
    [self.iCloudQuery disableUpdates];
    int resultCount = [self.iCloudQuery resultCount];
    NSURL *url= nil;
    BOOL createDataBaseSuccess = NO;
    if(resultCount==0)
    {
        url = [[self iCloudDocumentsURL]URLByAppendingPathComponent:DEFAULTDATABASENAME];
        //create mangedDocument
        [self setDataBaseManagerWithURL:url];
        [self setPersistentStoreOptionsInDocument:dataBaseManager];
        createDataBaseSuccess = YES;
        
    }else{//check if existed document has database document
        for(int i=0;i<resultCount;++i){
            NSMetadataItem *item = [self.iCloudQuery resultAtIndex:i];
            NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
            url = [self filePackageURLForCloudURL:url];
            if([[url lastPathComponent] isEqualToString:DEFAULTDATABASENAME])
            {
                [self setDataBaseManagerWithURL:url];
                createDataBaseSuccess = YES;
            }
        }
    }
    if(createDataBaseSuccess){
        [self setUplocationManager];
        [self.iCloudQuery enableUpdates];
    }else{
          NSLog(@"File On Cloud is not correct");
    }

}



#pragma mark -lifeCycle

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![self.iCloudQuery isStarted]) [self.iCloudQuery startQuery];
    [self.iCloudQuery enableUpdates];
    self.navigationController.navigationBarHidden = YES;
    self.mapView.mapType = MKMapTypeHybrid;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.iCloudQuery disableUpdates];
    //self.navigationController.navigationBarHidden = NO;
}


#pragma mark -CLLocationManagerDelegate Method
-(void)locationManager:(CLLocationManager *)manager 
   didUpdateToLocation:(CLLocation *)newLocation 
          fromLocation:(CLLocation *)oldLocation
{
    NSTimeInterval locationInterval;
    if(oldLocation){
        NSDate *locationDate=newLocation.timestamp;
        locationInterval=[locationDate timeIntervalSinceDate:oldLocation.timestamp];
        if(abs(locationInterval)<60)return;
    }
    //get all information for new waypoint
    NSDecimalNumber *latitude = [[NSDecimalNumber alloc] initWithDouble:(double)newLocation.coordinate.latitude];
    NSDecimalNumber *longitude = [[NSDecimalNumber alloc] initWithDouble:(double)newLocation.coordinate.longitude];
    NSDecimalNumber *horizontalAccuracy = [[NSDecimalNumber alloc] initWithDouble:(double)newLocation.horizontalAccuracy];
								 
	NSDecimalNumber *altitude=[[NSDecimalNumber alloc] initWithDouble:(double)newLocation.altitude];
    NSDecimalNumber *verticalAccuracy = [[NSDecimalNumber alloc] initWithDouble:(double)newLocation.verticalAccuracy];
    NSDate *visitDate = newLocation.timestamp;
    //to local time
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: visitDate];
    visitDate = [NSDate dateWithTimeInterval: seconds sinceDate: visitDate];

    //save all infomation into a dictionary
   NSMutableDictionary *wayPointDictionary = [NSMutableDictionary dictionary];
    [wayPointDictionary setValue:latitude forKey:@"latitude"];
    [wayPointDictionary setValue:longitude forKey:@"longitude"];
    [wayPointDictionary setValue:altitude forKey:@"altitude"];
    [wayPointDictionary setValue:verticalAccuracy forKey:@"verticalAccuracy"];
    [wayPointDictionary setValue:horizontalAccuracy forKey:@"horizontalAccuracy"];
    [wayPointDictionary setValue:visitDate forKey:@"date"];
    
    //core data operation
    compeltion_block_t addBlock;
    __block id ifSuccessAdd= nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    addBlock = ^(UIManagedDocument *context){
        ifSuccessAdd = [WayPoint addWayPointWith:wayPointDictionary inManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [CoreDataHelper useSharedMangedDocument:dataBaseManager toExecuteBlock:addBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    if(!oldLocation){
        [self upDateAnnotations];
    }
    //if ifSuccessAdd is nil, then it means we have not add anything into database,
    //then we do not need to update mapview
    if(!ifSuccessAdd)return;
    if(oldLocation && locationInterval>60){
        [self upDateAnnotations];
    }
}
#pragma mark -set alarm

//Following two functions are used for add alarm on the calender.
- (EKCalendar *)  getFirstModifiableLocalCalendar{
    
    EKCalendar *result = nil;
    
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    for (EKCalendar *thisCalendar in eventStore.calendars){
        if (thisCalendar.type == EKCalendarTypeLocal &&
            [thisCalendar allowsContentModifications]){
            return thisCalendar;
        }
    }
    return result;
}

- (void) addAlarmToCalendarTimeInterval:(double)time_interval 
                                  Title:(NSString *)title Notes:(NSString *)notes
{
    
    EKCalendar *targetCalendar = [self getFirstModifiableLocalCalendar];
    
    if (targetCalendar == nil){
        NSLog(@"Could not find the target calendar.");
        return;
    }
    
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    EKEvent *eventWithAlarm = [EKEvent eventWithEventStore:eventStore];
    
    eventWithAlarm.calendar = targetCalendar;
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:30.0f];
    NSDate *endDate = [startDate dateByAddingTimeInterval:time_interval];
    eventWithAlarm.startDate = startDate;
    eventWithAlarm.endDate = endDate;
    
    /* The alarm goes off two seconds before the event happens */
    EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:-2.0f];
    
    eventWithAlarm.title = title;
    eventWithAlarm.notes = notes;
    [eventWithAlarm addAlarm:alarm];
    
    NSError *saveError = nil;
    
    if ([eventStore saveEvent:eventWithAlarm
                         span:EKSpanThisEvent
                        error:&saveError]){
        NSLog(@"Saved an event that fires 30 seconds from now.");
    } else {
        NSLog(@"Failed to save the event. Error = %@", saveError);
    }
}


#pragma mark --region monitor
//When user enter a region monitored ny CLLocationManager, it will traverse the 
//alarmDictionary, and find the specific region set by user. Get the time interval
//user set and init an alarm
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    //here is used for test
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Cong!"
                              message:@"You have enter a position you set:"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Ok", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertView show];
    
    
    for(NSString *coordinate_key in alarmDictionary){
        NSArray *coordinateArr = [coordinate_key componentsSeparatedByString:@"_"];
        double latitude = [[coordinateArr objectAtIndex:0] doubleValue];
        double longitude = [[coordinateArr objectAtIndex:1] doubleValue];
        //if the error is less than 0.001 (coordinate), we will take it
        if(abs(region.center.latitude - latitude)<0.001 
           && abs(region.center.longitude - longitude)<0.001)
        {//Same
            double time_interval = [[alarmDictionary objectForKey:coordinate_key] doubleValue];
            [self addAlarmToCalendarTimeInterval:time_interval Title:@"Time to leave this place" Notes:nil];
            [alarmDictionary removeObjectForKey:coordinate_key];
            break;
        }
    }
}


#pragma mark -create waypoints summary TVC

//Set the table view appear on the left of the screen
-(wayPointsSummaryTableViewController *)myViewController
{
    if(!_myViewController)
    {
        _myViewController=[[wayPointsSummaryTableViewController alloc]init];
        _myViewController.view.hidden = YES;
        _myViewController.dataBase = dataBaseManager;
        _myViewController.view.autoresizingMask= UIViewAutoresizingFlexibleRightMargin;
        _myViewController.superMapView = self.mapView;
        _myViewController.view.frame = CGRectMake(0, 10, 90, (self.myViewController.view.frame.size.height)); 
        _myViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        _myViewController.view.opaque = NO;
        _myViewController.view.layer.cornerRadius = 5;
        [self.mapView addSubview:self.myViewController.view];
    }
    return _myViewController;
    
}

//Show or hide the wayPointsSummaryTableView
- (IBAction)wayPointsSumPressed:(id)sender {
    
    UITableView * myView = (UITableView *)self.myViewController.view;
    myView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1];
    if(!myView.isHidden)
    {//hide the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionReveal;
        transition.subtype = kCATransitionFromBottom;
        [myView.layer addAnimation:transition forKey:nil];
        myView.hidden=YES;
        //[myView removeFromSuperview];
    }else{//show the view

        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFromTop;
        [myView.layer addAnimation:transition forKey:nil];
        myView.hidden = NO;
        if(!self.mapTypeView.isHidden){
            [self moveDownTableView];
        }
        [self.myViewController.tableView reloadData];
    }
}

#pragma mark --segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"ShowWayPoint"]){
        if([segue.destinationViewController isKindOfClass:[MyLocationViewController class]]){
            [segue.destinationViewController performSelector:@selector(setMyWayPoint:) withObject:sender];
        
        }
        //do nothing
    }
    if([segue.identifier isEqualToString:@"ShowCurrentLocation"]){
        //do nothing
        if([segue.destinationViewController respondsToSelector:@selector(setCurrentWayPoint:)]){
            [segue.destinationViewController performSelector:@selector(setCurrentWayPoint:) withObject:sender];
        }
    }
}

#pragma mark --Show setting tool bar
//mapTypeView will show in the upper of the screen, it can change the type of map
-(void)mapTypePressed:(id)sender
{
    UISegmentedControl *button = (UISegmentedControl *)sender;
    switch (button.selectedSegmentIndex){
        case 0: self.mapView.mapType = MKMapTypeStandard;
            break;
        case 1: self.mapView.mapType = MKMapTypeHybrid;
            break;
        case 2: self.mapView.mapType = MKMapTypeSatellite;
            break;
        default: break;
    }
}

-(UIImageView *)mapTypeView
{
    if(!_mapTypeView){
        _mapTypeView = [[UIImageView alloc] init];
        _mapTypeView.frame = CGRectMake(5,6,(self.view.frame.size.width-50), 50);
        _mapTypeView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        _mapTypeView.opaque = NO;
        _mapTypeView.layer.cornerRadius = 7;
        _mapTypeView.hidden = YES;
        _mapTypeView.userInteractionEnabled = YES;
        
        NSArray *itemArray = [NSArray arrayWithObjects:@"Normal",@"Hybird",@"Satellite", nil];
        UISegmentedControl *typeController = [[UISegmentedControl alloc] initWithItems:itemArray ];
        //the second segment in hybird, and the default map type is hybird
        typeController.selectedSegmentIndex = 1;
        typeController.segmentedControlStyle = UISegmentedControlStyleBar;
        typeController.frame = CGRectMake(10,7,(self.view.frame.size.width-70),37);
        [typeController setTintColor:[UIColor colorWithWhite:0.45 alpha:1]];
        [typeController addTarget:self action:@selector(mapTypePressed:) forControlEvents:UIControlEventValueChanged];
        [_mapTypeView addSubview:typeController];
    }
    return _mapTypeView;
}

//when the maptype view show up, if the tableView is not hidden, then 
//we need to move the table view down to avoid overlap
//and when the maptype move back, we need to move up the tableView
- (void)moveDownTableView
{
    //move down
    CGFloat moveDistance = 50.0;
    [UIView setAnimationDuration:0.5];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, moveDistance);
    self.myViewController.view.transform = transform;
    [UIView commitAnimations];
}

- (void)moveUpTableView
{
    //move down
    CGFloat moveDistance = -6.0;
    [UIView setAnimationDuration:0.5];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, moveDistance);
    self.myViewController.view.transform = transform;
    [UIView commitAnimations];
}

- (void)mapDisplayChanged
{

    if(!self.mapTypeView.isHidden)
    {//hide the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionReveal;
        transition.subtype = kCATransitionFromLeft;
        [self.mapTypeView.layer addAnimation:transition forKey:nil];
        self.mapTypeView.hidden=YES;
        if(!self.myViewController.tableView.isHidden){
            [self moveUpTableView];
        }
    }else{//show the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionFromLeft;
        [self.mapTypeView.layer addAnimation:transition forKey:nil];
        self.mapTypeView.hidden = NO;
        if(!self.myViewController.tableView.isHidden){
            [self moveDownTableView];
        }
    }
    [self.view addSubview:self.mapTypeView];
}



-(void)ShowPieChart
{
    [self performSegueWithIdentifier:@"ShowPieChart" sender:nil];
    
}


//get the current location's waypoint
-(WayPoint *)findCurrentLocation
{
    compeltion_block_t findBlock;
    __block NSArray *allWayPoints= nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    findBlock = ^(UIManagedDocument *context){
        allWayPoints = [WayPoint getAllWayPointsInManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [CoreDataHelper useSharedMangedDocument:dataBaseManager toExecuteBlock:findBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    if(allWayPoints)return [allWayPoints objectAtIndex:0];
    else return nil;
}

-(void)ShowCurrentLocation
{
    WayPoint *currentWayPoint = [self findCurrentLocation];
    if(currentWayPoint){
        [self performSegueWithIdentifier:@"ShowCurrentLocation" sender:currentWayPoint];
    }else{
        NSString *message = @"Current Location is Not Available!";
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Not Available"
                                  message:message
                                  delegate:self
                                  cancelButtonTitle:@"Cancle"
                                  otherButtonTitles:nil, nil];
        [alertView show];
        
    }
    
}

#pragma mark --setting View

//Setting View is shown on the right part of the screen, it like a tool bar
//And there are three button on it, ShowPieChart, CurrentLocation and ShowMapTypeView
-(UIImageView *)settingView
{
    if(!_settingView){
        self.settingView = [[UIImageView alloc] init];
        self.settingView.userInteractionEnabled = YES;
        self.settingView.hidden = YES;
        self.settingView.frame = CGRectMake((self.view.frame.size.width-40),0,40,self.view.frame.size.height);
        self.settingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.settingView.opaque = NO;
        
        //set Change MapView Button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        //[button setTitle:@"Show View" forState:UIControlStateNormal];
        
        button.frame = CGRectMake(3, 15, 35, 35);//width and height should be same value
        button.clipsToBounds = YES;
        [button addTarget:self action:@selector(mapDisplayChanged) forControlEvents:UIControlEventTouchUpInside];
        //set button style
        [button setImage:[UIImage imageNamed:@"Maptype.png"] forState:UIControlStateNormal];
        button.layer.cornerRadius = 15;//half of the width
        button.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
        [self.settingView addSubview:button];
        
        //set Show Statistic Button
        UIButton *statisticButton = [UIButton buttonWithType:UIButtonTypeCustom];
        statisticButton.frame = CGRectMake(3, 60, 35, 35);
        statisticButton.clipsToBounds = YES;
        [statisticButton addTarget:self action:@selector(ShowPieChart) forControlEvents:UIControlEventTouchUpInside];
        [statisticButton setImage:[UIImage imageNamed:@"PieChart.png"] forState:UIControlStateNormal];
        statisticButton.layer.cornerRadius = 15;
        statisticButton.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
        [self.settingView addSubview:statisticButton];
        
        //set Show Current Location Button
        UIButton *currentLocationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        currentLocationButton.frame = CGRectMake(3, 105, 35, 35);
        currentLocationButton.clipsToBounds = YES;
        [currentLocationButton addTarget:self action:@selector(ShowCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
        [currentLocationButton setImage:[UIImage imageNamed:@"currentLocation.png"] forState:UIControlStateNormal];
        currentLocationButton.layer.cornerRadius = 15;
        currentLocationButton.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.4];
        [self.settingView addSubview:currentLocationButton];
        
    }
    return _settingView;
    
}



- (IBAction)showSettingViewPressed:(id)sender {

    [self.mapView addSubview:self.settingView];
    if(!self.settingView.isHidden)
    {//hide the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionReveal;
        transition.subtype = kCATransitionFromBottom;
        [self.settingView.layer addAnimation:transition forKey:nil];
        self.settingView.hidden=YES;
    }else{//show the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFromTop;
        [self.settingView.layer addAnimation:transition forKey:nil];
        self.settingView.hidden = NO;
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
