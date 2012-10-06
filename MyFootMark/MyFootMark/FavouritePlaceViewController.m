//
//  FavouritePlaceViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "FavouritePlaceViewController.h"
#import "MyPlace.h"
#import "MainMapViewController.h"
#import "MyPlace+Operations.h"
#import "CoreDataHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "BumpViewController.h"

@interface FavouritePlaceViewController ()
@property (nonatomic, strong)NSArray *allPlaces;
@end

@implementation FavouritePlaceViewController
@synthesize allPlaces = _allPlaces;

-(void)setAllPlaces:(NSArray *)allPlaces
{
    _allPlaces = allPlaces;
    [self.tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)ShowAllPlaces
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] 
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spinner startAnimating];
    __block NSArray *places;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    dispatch_queue_t downloadQueue = dispatch_queue_create("My Place downloader", NULL);
    dispatch_async(downloadQueue, ^{
        compeltion_block_t queryBlock;
        queryBlock = ^(UIManagedDocument *dataBaseManager){
            places = [MyPlace getAllPlacesInManagedObjectContext:dataBaseManager.managedObjectContext];
        };
        [MainMapViewController performBlock:queryBlock];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem = nil;
            self.allPlaces = places;
        });    
    });
    dispatch_release(downloadQueue);
}

-(void)viewWillAppear:(BOOL)animated
{
    //if allPlaces is empty when view apprear, it means its previous controller is
    //MainMapViewController, then this table should show all places. Else it will show the 
    //match bump result.
    int previousVCIndex = [self.navigationController.viewControllers 
                           indexOfObject:self.navigationController.topViewController]-1;
    
    id previousController = [self.navigationController.viewControllers 
                             objectAtIndex:previousVCIndex];
    if([previousController isKindOfClass:[BumpViewController class]]){
        [self.tableView reloadData];
    }else{
        [self ShowAllPlaces];
    }
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - Table view data source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allPlaces count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CustomTableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    } 
    
    MyPlace *place = [self.allPlaces objectAtIndex:indexPath.row];
    cell.imageView.hidden = YES;
    cell.textLabel.text = place.placename;
    cell.detailTextLabel.text = place.address;
    __block UIImage *placeImage;
    dispatch_queue_t downloadQueue = dispatch_queue_create("My Place Image downloader", NULL);
    dispatch_async(downloadQueue, ^{
        placeImage = [UIImage imageWithData:place.imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = placeImage;
            cell.imageView.hidden = NO;
            [cell setNeedsLayout];
        });    
    });
    dispatch_release(downloadQueue);
    //cell.imageView.image = [UIImage imageWithData:place.imageData];
    cell.layer.cornerRadius = 5;//half of the width
    cell.selectedBackgroundView = UITableViewCellSelectionStyleNone;
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[NSIndexPath class]]) {
        indexPath = (NSIndexPath *)sender;
    } else if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    } else if (!sender || (sender == self) || (sender == self.tableView)) {
        indexPath = [self.tableView indexPathForSelectedRow];
    }
    if([segue.identifier isEqualToString:@"ShowDetailThroughPlaceTVC"]){
        if([segue.destinationViewController respondsToSelector:@selector(setMyPlace:)]){
            [segue.destinationViewController performSelector:@selector(setMyPlace:) withObject:[self.allPlaces objectAtIndex:indexPath.row]];
        }
    }
    
}

@end
