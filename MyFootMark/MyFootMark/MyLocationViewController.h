//
//  MyLocationViewController.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/3/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WayPoint.h"
#import "BaseTableViewController.h"

@interface MyLocationViewController : BaseTableViewController
@property (nonatomic, strong)WayPoint *myWayPoint;
@end
