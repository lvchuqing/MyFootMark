//
//  PieChartViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/6/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//
#import "PieChartView.h"
#import "PieChartViewController.h"
#import "WayPoint+Operations.h"
#import "CoreDataHelper.h"
#import "MainMapViewController.h"
#import "Utility.h"

@interface PieChartViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet PieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UIScrollView *ScrollView;

@end

@implementation PieChartViewController
@synthesize pieChartView = _pieChartView;
@synthesize ScrollView = _ScrollView;

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //calculate the statistic in recent 24 hours
    [self calculateStatistic];
    //self.navigationController.navigationBarHidden = NO;
    
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
}


-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.pieChartView;
}

-(NSString *)getAddressStr:(WayPoint *)wayPointNow
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[wayPointNow.latitude doubleValue] longitude:[wayPointNow.longitude doubleValue]];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    call_back_block setStr;
    __block NSString *locationAddr;
    setStr = ^(NSString *address){
        locationAddr = address;
        dispatch_semaphore_signal(sema);
    };
    [Utility addressForLocation:location withBlock:setStr];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    return locationAddr;
}

-(NSArray *)getAllWayPoints
{
    __block NSArray *wayPoints;
    compeltion_block_t queryBlock;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    queryBlock = ^(UIManagedDocument *context){
        wayPoints = [WayPoint getAllWayPointsInManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [MainMapViewController performBlock:queryBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    return wayPoints;
}


#define ONE_DAY_TIME_INTERVAL 60*60*24

-(void)calculateStatistic
{
    NSArray *wayPoints = [self getAllWayPoints];
    
    NSMutableArray *wayPointsToday = [NSMutableArray array];
    NSMutableArray *timeForEachWayPoint = [NSMutableArray array];
    NSMutableArray *addressArray = [NSMutableArray array];
    NSDate *now = [NSDate date];
    NSDate *previousDate = now;
    WayPoint *previousWayPoints;
    double totalTime = 0;
    for(WayPoint *wayPointNow in wayPoints)
    {
        if(abs([now timeIntervalSinceDate:wayPointNow.visitTime])>ONE_DAY_TIME_INTERVAL)break;
        if(previousWayPoints && [WayPoint distanceOfTwoWayPoints:previousWayPoints and:wayPointNow]<200)
        {//the distance of these two way points are to short, so we won't count it
            continue;
        }else{
           
            NSNumber *timeSpan = [NSNumber numberWithDouble:abs([wayPointNow.visitTime timeIntervalSinceDate:previousDate])]; 
            NSString *locationAddr = [self getAddressStr:wayPointNow];
            //I will check if the address string for each waypoint are same.
            //If they are same I will consider it as same place and combine them
            BOOL combineSuccess = NO;
            for(int i=0; i<[addressArray count]; ++i){
                if([[addressArray objectAtIndex:i] isEqualToString:locationAddr]){
                    //combine two location
                    int timeSpanTillNow = [timeSpan intValue] + [[timeForEachWayPoint objectAtIndex:i] intValue];
                    NSNumber *timeTillNow = [NSNumber numberWithInt:timeSpanTillNow];
                    [timeForEachWayPoint removeObjectAtIndex:i];
                    [timeForEachWayPoint insertObject:timeTillNow atIndex:i];
                    combineSuccess = YES;
                }
            }
            if(!combineSuccess){
                [wayPointsToday addObject:wayPointNow];
                [timeForEachWayPoint addObject:timeSpan];
                [addressArray addObject:locationAddr];
            }
            previousWayPoints = wayPointNow;
            previousDate = wayPointNow.visitTime;

            totalTime += [timeSpan doubleValue];
        }
    } 
    
    //check if they have same address, if it is then 
    
    
    self.pieChartView.addressArr = addressArray;
    self.pieChartView.allTimeSpan = totalTime;
    //self.pieChartView.wayPointArr = wayPointsToday;
    self.pieChartView.timeArr = timeForEachWayPoint;
    [self setScrollViewSize:[wayPointsToday count]];

}

-(void)setScrollViewSize:(int)numberOfWayPoint
{
    int view_height = PIE_CHART_RADIUS*2 + (RECT_RADIUS+SEPARATOR_HEIGHT_OF_RADIUS) *numberOfWayPoint + MARGIN;
    self.pieChartView.frame = CGRectMake(0, 40, 320, view_height);
    self.ScrollView.delegate = self;
    CGSize scrollViewSize = CGSizeMake(320, view_height);
    self.ScrollView.contentSize = scrollViewSize;
    [self.pieChartView setNeedsLayout];
    
}



- (void)viewDidUnload
{
    [self setPieChartView:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
