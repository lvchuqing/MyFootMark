//
//  wayPointsSummaryTableViewController.h
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//


@interface wayPointsSummaryTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UIManagedDocument *dataBase;
@property (nonatomic, weak)id superMapView;
@end
