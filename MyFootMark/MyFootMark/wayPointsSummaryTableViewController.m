//
//  wayPointsSummaryTableViewController.m
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "wayPointsSummaryTableViewController.h"
#import "WayPoint+Operations.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>
#import <Foundation/Foundation.h>
#import "CoreDataHelper.h"
#import "WayPoint+Operations.h"
#import <MapKit/MapKit.h>


@interface wayPointsSummaryTableViewController()
@property (nonatomic, strong)NSArray *wayPointsArray;
@property (nonatomic, strong)NSArray *sectionTitle;
@end

@implementation wayPointsSummaryTableViewController
@synthesize wayPointsArray = _wayPointsArray;
@synthesize dataBase = _dataBase;
@synthesize sectionTitle = _sectionTitle;
@synthesize superMapView = _superMapView;

-(void)setDataBase:(UIManagedDocument *)dataBase
{
    //set wayPointsArray
    _dataBase =dataBase;
    //[self.tableView reloadData];
}


#pragma mark-TVC dataSource
#define SECONDSINADAY 60*60*24

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    compeltion_block_t queryBlock;
    __block NSArray *allDayRecords;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    queryBlock = ^(UIManagedDocument *context){
        allDayRecords=[WayPoint numberOfDifferentDaysInDBinManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [CoreDataHelper useSharedMangedDocument:self.dataBase toExecuteBlock:queryBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    { //wait for compete execute tht block
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    self.sectionTitle = allDayRecords;
    return [allDayRecords count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sectionTitle objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *dateStr = [self.sectionTitle objectAtIndex:section];
    compeltion_block_t queryBlock;
    __block int count =0;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    queryBlock = ^(UIManagedDocument *context){
        count = [WayPoint numberOfWayPointsinDay:dateStr inManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [CoreDataHelper useSharedMangedDocument:self.dataBase toExecuteBlock:queryBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    { //wait for compete execute tht block
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    return count;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,tableView.bounds.size.width,30)];
    [headerView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, tableView.bounds.size.width - 10, 18)];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:16.0];
    label.backgroundColor = [UIColor clearColor];
    [headerView addSubview:label];
    return headerView;
}

- (WayPoint *)findWayPointForIndexPath:(NSIndexPath *)indexPath
{
    NSString *dateStr = [self.sectionTitle objectAtIndex:indexPath.section];
    compeltion_block_t queryBlock;
    __block NSArray *wayPointeArrayinOneDay;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    queryBlock = ^(UIManagedDocument *context){
        wayPointeArrayinOneDay = [WayPoint wayPointsInDay:dateStr inManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [CoreDataHelper useSharedMangedDocument:self.dataBase toExecuteBlock:queryBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    { //wait for compete execute tht block
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    
    WayPoint *myWayPoint = [wayPointeArrayinOneDay objectAtIndex:indexPath.row];
    return myWayPoint;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    WayPoint *myWayPoint = [self findWayPointForIndexPath:indexPath];
    NSDate *visitDate = myWayPoint.visitTime;
    //Divide the date object and find out the exact hour, minute and second of current time
    //This is for easily display time 
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:visitDate];
    cell.textLabel.text= [NSString stringWithFormat:@"    %d:%d",[components hour],[components minute]];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5,15,15,15)];
    imageView.contentMode = UIViewContentModeLeft;
    imageView.image = [UIImage imageNamed:@"15X15.png"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell addSubview:imageView];

    cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    cell.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WayPoint *myWayPoint = [self findWayPointForIndexPath:indexPath];
    if(!self.superMapView)return;
    MKMapView *mapView = (MKMapView *)self.superMapView;

    mapView.centerCoordinate = CLLocationCoordinate2DMake([myWayPoint.latitude doubleValue], [myWayPoint.longitude doubleValue]);
}

@end
