//
//  PieChartView.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/6/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WayPoint.h"

#define PIE_CHART_RADIUS 100
#define RECT_RADIUS 30
#define SEPARATOR_HEIGHT_OF_RADIUS 20
#define MARGIN 150
#define DEFAULT_VIEW_WIDTH 320
#define DEFAULT_VIEW_HEIGHT 416
#define ANCHOR_CENTER 0
#define ANCHOR_TOP 1
#define ANCHOR_LEFT 2
#define ANCHOR_BOTTOM 3
#define ANCHOR_RIGHT 4
#define HORIZONTAL_TEXT_MARGIN 6
#define VERTICAL_TEXT_MARGIN 3
#define MAX_TEXT_LENGTH_PER_LINE 39

#define HASH_MARK_FONT_SIZE 12.0

//address Arr save all address for each place
//timeArr save all times spend in each place
//allTimeSpan save the total time
@interface PieChartView : UIView

@property (strong, nonatomic)NSArray *timeArr;
@property (strong, nonatomic)NSArray *addressArr;
@property double allTimeSpan;
@end
