//
//  BumpViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/5/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "BumpViewController.h"
#import "BumpClient.h"
#import "MyPlace+Operations.h"
#import "MainMapViewController.h"
#import "BumpUtility.h"
#import "WayPoint+Operations.h"
#import <AudioToolbox/AudioToolbox.h>

@interface BumpViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *matchIndexLabel;
@property (weak, nonatomic) IBOutlet UIButton *bumpToPlayButton;
@property (strong, nonatomic)NSMutableArray *allPlaces;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic)NSArray *allMatchPlaces;
@property (weak, nonatomic) IBOutlet UIButton *showResultButton;
@property BOOL stopBump;

@end

@implementation BumpViewController
@synthesize imageView = _imageView;
@synthesize matchIndexLabel = _matchIndexLabel;
@synthesize bumpToPlayButton = _bumpToPlayButton;
@synthesize allPlaces = _allPlaces;
@synthesize spinner = _spinner;
@synthesize allMatchPlaces = _allMatchPlaces;
@synthesize showResultButton = _showResultButton;
@synthesize stopBump = _stopBump;
@synthesize successSound = _successSound;

- (IBAction)bumpToPlay:(id)sender {
    
    //begin Bump
    self.stopBump = NO;
    //set spinner
    self.bumpToPlayButton.hidden = YES;
    self.spinner.hidden = NO;
    //stop user to perform segue
    self.showResultButton.userInteractionEnabled = NO;
    [self.spinner startAnimating];
    
    
    BumpMatchBlock bmb;
    bmb = ^(BumpChannelID channel){
        if(self.stopBump)return;
        NSString *user = [[BumpClient sharedClient] userIDForChannel:channel];
        self.matchIndexLabel.text = [@"Matched with user:" stringByAppendingString:user];
        [[BumpClient sharedClient] confirmMatch:YES onChannel:channel];
    };
    
    BumpChannelConfirmedBlock bccb;
    bccb = ^(BumpChannelID channel){
        if(self.stopBump)return;
        NSString *user = [[BumpClient sharedClient] userIDForChannel:channel];
        self.matchIndexLabel.text = [NSString stringWithFormat:@"Channel with %@ confirmed", user];
        //send shared data
        NSData *myData = [self serialize];
        if(myData==nil)return;
        [[BumpClient sharedClient] sendData:myData toChannel:channel];
    };
    
    BumpDataReceivedBlock bdrb;
    bdrb = ^(BumpChannelID channel, NSData *data){
        if(self.stopBump)return;
        if(data == nil)return;
        NSString *user = [[BumpClient sharedClient] userIDForChannel:channel];
        self.matchIndexLabel.text = [NSString stringWithFormat:@"Data received from %@", user];
        //deal with data received 
        [self deserializeData:data];
    };
    
    BumpConnectionStateChangedBlock bcscb;
    bcscb = ^(BOOL connected){
        if(self.stopBump)return;
        if(connected){
            self.matchIndexLabel.text = @"Bump connected...";
        }else{
            self.matchIndexLabel.text = @"Bump disconnected...";
            [[BumpClient sharedClient]connect];
        }
    };
    
    BumpEventBlock beb;
    beb = ^(bump_event event){
        if(self.stopBump)return;
        switch(event){
            case BUMP_EVENT_BUMP:
                self.matchIndexLabel.text = @"Bump detected.";
                break;
            case BUMP_EVENT_NO_MATCH:
                self.matchIndexLabel.text = @"No match! Try again!";
                break;
        }
    };
    
    [BumpUtility configureBumpWithsetMatchBlock:bmb setChannelConfirmedBlock:bccb setDataReceivedBlock:bdrb setConnectionStateChangedBlock:bcscb setBumpEventBlock:beb];
}


-(NSData *)serialize{
    
    compeltion_block_t queryBlock;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    queryBlock = ^(UIManagedDocument *context){
        self.allPlaces = [[MyPlace getAllPlacesInManagedObjectContext:context.managedObjectContext] mutableCopy];
        dispatch_semaphore_signal(sema);
    };
    [MainMapViewController performBlock:queryBlock];
    while(dispatch_semaphore_wait(sema,DISPATCH_TIME_NOW))
    {
       [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    }
    dispatch_release(sema);
    if(!self.allPlaces)return nil;
    NSMutableArray *places = [NSMutableArray array];
    for(MyPlace *place in self.allPlaces){
        NSMutableDictionary *myDict = [NSMutableDictionary dictionary];
        [myDict setValue:place.placename forKey:@"placename"];
        [myDict setValue:place.latitude forKey:@"latitude"];
        [myDict setValue:place.longitude forKey:@"longitude"];
        [places addObject:myDict];
    }
    NSData *serializedDara = [NSKeyedArchiver archivedDataWithRootObject:places];
    return serializedDara;
}
-(void)playSuccessfulSound
{

    NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/success.wav"];
    
	//declare a system sound
	UInt32 soundID;
    
	//Get a URL for the sound file
	NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    
	//Use audio sevices to create the sound
	AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
	//Use audio services to play the sound
	AudioServicesPlaySystemSound(soundID);
}

-(void)deserializeData:(NSData *) myData
{
    AudioServicesPlaySystemSound(self.successSound);
    NSMutableArray *match = [NSMutableArray array];
    if(!self.allPlaces)NSLog(@"Serialize Data Wrong!");
     NSArray *myArr = [NSKeyedUnarchiver unarchiveObjectWithData:myData];
    for(MyPlace *selfPlace in self.allPlaces){
        for(NSDictionary *receivedPlace in myArr){
            //Calculate Distance of two coordination
            double A_Latitude = [selfPlace.latitude doubleValue];
            double A_Longitude = [selfPlace.longitude doubleValue];
            double B_Latitude = [[receivedPlace valueForKey:@"latitude"] doubleValue];
            double B_Longitude = [[receivedPlace valueForKey:@"longitude"] doubleValue];
            double distances = [WayPoint distanceOfALatitude:A_Latitude ALongitude:A_Longitude andBLatitude:B_Latitude BLongitude:B_Longitude];
            if(distances<400){
                [match addObject:selfPlace];
                //Do not need to check other places in received Place
                break;
            }//end if
        }//end for
    }//end for
    [self CalculateMatchIndex:match];
    //restore bumpToPlayButton
    self.spinner.hidden = YES;
    self.bumpToPlayButton.hidden = NO;
    //stop receive bump data
    self.stopBump = YES;
    
    
    
    
}

- (void)CalculateMatchIndex:(NSArray *)matches
{
    double totalPlace = [self.allPlaces count];
    double matchPlace = [matches count];
    double index = (matchPlace/totalPlace)*100;
    
    //set segue data
    self.allMatchPlaces = matches;
    self.showResultButton.userInteractionEnabled = YES;
    
    
    NSString *displayStr;
    if(index == 0){
        self.imageView.image = [UIImage imageNamed:@"0.png"];
        displayStr = @"You have no hope! Match Index:";
    }else if(index<20){
        self.imageView.image = [UIImage imageNamed:@"20.png"];
        displayStr = @"Woops! You are stranger! Match Index:";
    }else if(index<40){
        self.imageView.image = [UIImage imageNamed:@"40.png"];
        displayStr = @"You need to work hard! Match Index:";
    }else if(index<60){
        self.imageView.image = [UIImage imageNamed:@"60.png"];
        displayStr = @"Promising! Match Index:";
    }else if(index<80){
        self.imageView.image = [UIImage imageNamed:@"80.png"];
        displayStr = @"You must can be good friend! Match Index:";
    }else{
        self.imageView.image = [UIImage imageNamed:@"100.png"];
        displayStr = @"Congratulations! You know what you should do. Match Index:";
    }
    NSString *indexStr = [NSString stringWithFormat:@"%0.1f%%",index];
    self.matchIndexLabel.text = [displayStr stringByAppendingString:indexStr];
    

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.destinationViewController respondsToSelector:@selector(setAllPlaces:)]){
        [segue.destinationViewController performSelector:@selector(setAllPlaces:) withObject:self.allMatchPlaces];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)configureSuccessSound
{
    NSString *successPath = [[NSBundle mainBundle] pathForResource:@"success" ofType:@"wav"];
    NSURL *successURL = [NSURL fileURLWithPath:successPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)successURL, &_successSound);
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.spinner.hidden = YES;
    self.stopBump = YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self configureSuccessSound];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidUnload {
    [self setImageView:nil];
    [self setMatchIndexLabel:nil];
    [self setMatchIndexLabel:nil];
    [self setBumpToPlayButton:nil];
    [self setSpinner:nil];
    [self setShowResultButton:nil];
    [super viewDidUnload];
}
@end
