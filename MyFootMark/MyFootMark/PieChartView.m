//
//  PieChartView.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/6/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "PieChartView.h"
#import "Utility.h"

@interface PieChartView()
@property (strong, nonatomic)NSArray *colorArr;

@end

@implementation PieChartView

@synthesize timeArr = _timeArr;
@synthesize allTimeSpan = _allTimeSpan;
@synthesize colorArr = _colorArr;
@synthesize addressArr = _addressArr;


/**************************************************************
 *This color array save 9 different colors, if ths component
 *number in the pie chart is less than 9, then it won't repeat.
 *When there are more than 9 colors, it will choose the (num%9)th
 *color and change its alpha value to make it different.
 *I do not choose to use random number to generate color is because 
 *sometimes the color generated will be very similar and cannot
 *distinguish two nearby component
 ***************************************************************/
-(NSArray *)colorArr
{
    if(!_colorArr){
        NSMutableArray * temp = [NSMutableArray array];
        [temp addObject:[UIColor redColor]];
        [temp addObject:[UIColor greenColor]];
        [temp addObject:[UIColor blueColor]];
        [temp addObject:[UIColor cyanColor]];
        [temp addObject:[UIColor yellowColor]];
        [temp addObject:[UIColor magentaColor]];
        [temp addObject:[UIColor orangeColor]];
        [temp addObject:[UIColor purpleColor]];
        [temp addObject:[UIColor brownColor]];
        _colorArr = temp;
    }
    return _colorArr;
}




#define LINE_HEIGHT 12
#define RECT_BEGIN_X 30

- (void)drawString:(NSString *)text atPoint:(CGPoint)location withAnchor:(int)anchor
{
	if ([text length])
	{
		UIFont *font = [UIFont systemFontOfSize:HASH_MARK_FONT_SIZE];
		
		CGRect textRect;
		textRect.size = [text sizeWithFont:font];
		textRect.origin.x = location.x - textRect.size.width / 2;
		textRect.origin.y = location.y - textRect.size.height / 2;
		
		switch (anchor) {
			case ANCHOR_TOP: textRect.origin.y += textRect.size.height / 2 + VERTICAL_TEXT_MARGIN; break;
			case ANCHOR_LEFT: textRect.origin.x += textRect.size.width / 2+ HORIZONTAL_TEXT_MARGIN; break;
			case ANCHOR_BOTTOM: textRect.origin.y -= textRect.size.height / 2 + VERTICAL_TEXT_MARGIN; break;
			case ANCHOR_RIGHT: textRect.origin.x -= textRect.size.width / 2+ HORIZONTAL_TEXT_MARGIN; break;
		}
		
		[text drawInRect:textRect withFont:font];
	}
}

-(UIColor *)distinctColorFillAt:(int)index andContext:(CGContextRef)ctx
{
    UIColor *color;
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0;
    int round = index%[self.colorArr count];
    color = [self.colorArr objectAtIndex:round];
    if(index>=[self.colorArr count]){
        //change alpha to avoid duplication
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        CGContextSetRGBFillColor(ctx,red, green, blue, abs(alpha-0.2*round));
    }else{
        CGContextSetFillColorWithColor(ctx, color.CGColor);
    }
    return color;
}


-(void)drawPieChart
{
    int pie_center_x = DEFAULT_VIEW_WIDTH/2;
    int pie_center_y = DEFAULT_VIEW_HEIGHT/3;
    
    //mult is the degree for one second
    float mult = (double)360/self.allTimeSpan;
    float startDegree = 0;
    float endDegree = 0;
    
    int rect_begin_x = RECT_BEGIN_X;
    int rect_begin_y = pie_center_y + PIE_CHART_RADIUS + 2*SEPARATOR_HEIGHT_OF_RADIUS;
    
    int text_begin_x = rect_begin_x + RECT_RADIUS + SEPARATOR_HEIGHT_OF_RADIUS -10;
    int text_begin_y = rect_begin_y + 2;//- SEPARATOR_HEIGHT_OF_RADIUS;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(ctx, 2.0);
    
    
    
    int total = [self.timeArr count];
    for(int i = 0; i<total; ++i){
        endDegree = startDegree + [[self.timeArr objectAtIndex:i] doubleValue]*mult;
        if(startDegree != endDegree){
            
            UIColor *color= [self distinctColorFillAt:i andContext:ctx];
            //draw arc
            CGContextMoveToPoint(ctx, pie_center_x, pie_center_y);
            CGContextAddArc(ctx, pie_center_x, pie_center_y, PIE_CHART_RADIUS, (startDegree)*M_PI/180, (endDegree)*M_PI/180, 0);
            CGContextClosePath(ctx);
            CGContextFillPath(ctx);
            
            //draw rectangle
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillRect(ctx, CGRectMake(rect_begin_x, rect_begin_y, RECT_RADIUS, RECT_RADIUS));
            rect_begin_y += RECT_RADIUS+SEPARATOR_HEIGHT_OF_RADIUS;
            
            //draw text
            NSString *address = [self.addressArr objectAtIndex:i];
            int lineNo = 0;
            while(address){
                NSString *lineStr;
                CGPoint point = CGPointMake(text_begin_x, text_begin_y);
                if(address.length >= MAX_TEXT_LENGTH_PER_LINE){
                    lineStr = [address substringToIndex:MAX_TEXT_LENGTH_PER_LINE - 1];
                    address  = [address substringFromIndex:MAX_TEXT_LENGTH_PER_LINE];
                    [self drawString:lineStr atPoint:point withAnchor:ANCHOR_LEFT];
                }else{
                    [self drawString:address atPoint:point withAnchor:ANCHOR_LEFT];
                    break;
                }
                text_begin_y += LINE_HEIGHT;
                lineNo ++;
            }
            text_begin_y += RECT_RADIUS + SEPARATOR_HEIGHT_OF_RADIUS - lineNo*LINE_HEIGHT;
            
            
        }
        startDegree = endDegree;
    }
}



- (void)drawRect:(CGRect)rect
{
    [self drawPieChart];
}




@end
