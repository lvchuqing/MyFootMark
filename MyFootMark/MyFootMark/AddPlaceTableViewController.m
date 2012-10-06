//
//  AddPlaceTableViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "AddPlaceTableViewController.h"
#import "WayPoint.h"
#import <MessageUI/MessageUI.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "Utility.h"
#import <Twitter/Twitter.h>
#import <CoreFoundation/CoreFoundation.h>
#import "MainMapViewController.h"
#import "MyPlace+Operations.h"
#import "FavouritePlaceViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BumpUtility.h"


@interface AddPlaceTableViewController ()<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *fromFileButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UIImageView *displayImageView;
@property (strong, nonatomic)UIImageView *bumpNotificationView;
@property (strong, nonatomic)CMMotionManager *motionManager;
@property (strong, nonatomic)WayPoint *myWayPoint;
@property (strong, nonatomic)MyPlace *myPlace;
@property (strong, nonatomic)UILabel *notificationForBump;
@property (strong, nonatomic)UIActivityIndicatorView *spinner;
@property BOOL savingState;
@property (strong, nonatomic)NSNumber *bump_altitude;
@property (strong, nonatomic)NSNumber *bump_latitude;
@property (strong, nonatomic)NSNumber *bump_longitude;
@property SystemSoundID successSound;
@end

@implementation AddPlaceTableViewController
@synthesize fromFileButton = _fromFileButton;
@synthesize takePhotoButton = _takePhotoButton;
@synthesize nameTextField = _nameTextField;
@synthesize addressTextField = _addressTextField;
@synthesize displayImageView = _displayImageView;
@synthesize myWayPoint = _myWayPoint;
@synthesize myPlace = _myPlace;
@synthesize bumpNotificationView = _bumpNotificationView;
@synthesize motionManager = _motionManager;
@synthesize notificationForBump = _notificationForBump;
@synthesize spinner = _spinner;
@synthesize savingState = _savingState;
@synthesize bump_altitude = _bump_altitude;
@synthesize bump_longitude = _bump_longitude;
@synthesize bump_latitude = _bump_latitude;
@synthesize successSound = _successSound;






#pragma  mark -TextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //placeholder folder name cannot be empty
    if([textField.text isEqualToString:@""])return NO;
    else{
        if(textField == self.nameTextField){
            UIFont *myBoldSystemFontForName = [ UIFont systemFontOfSize: 15.0 ];
            self.nameTextField.font = myBoldSystemFontForName;
        }
        [textField resignFirstResponder];
        return YES;
    }
}

-(void)setButtonTitle:(NSString *)title
{
    UIBarButtonItem *barButton = self.navigationItem.rightBarButtonItem;
    [barButton setTitle:title];
    if([title isEqualToString:@"Save"]){
        self.addressTextField.userInteractionEnabled = YES;
        self.nameTextField.userInteractionEnabled = YES;
        self.fromFileButton.userInteractionEnabled = YES;
        self.takePhotoButton.userInteractionEnabled = YES;
        self.savingState = NO;
    }else if([title isEqualToString:@"Edit"]){
        self.addressTextField.userInteractionEnabled = NO;
        self.nameTextField.userInteractionEnabled = NO;
        self.fromFileButton.userInteractionEnabled = NO;
        self.takePhotoButton.userInteractionEnabled = NO;
        self.savingState = YES;
    }
}


-(void)pushNotificationWithContent:(NSString *)content
{
    UILocalNotification *locationNotification = [[UILocalNotification alloc] init];
    locationNotification.alertBody=content;
    locationNotification.alertAction=@"Ok";
    locationNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:locationNotification];
    
}


-(UIImagePickerController *)setUpPicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    return picker;
}

-(UIImage *) resizedImage: (UIImage *)inImage withSize:(CGRect)thumbRect
{
	CGImageRef			imageRef = [inImage CGImage];
	CGImageAlphaInfo	alphaInfo = CGImageGetAlphaInfo(imageRef);
	
	// There's a wierdness with kCGImageAlphaNone and CGBitmapContextCreate
	// see Supported Pixel Formats in the Quartz 2D Programming Guide
	// Creating a Bitmap Graphics Context section
	// only RGB 8 bit images with alpha of kCGImageAlphaNoneSkipFirst, kCGImageAlphaNoneSkipLast, kCGImageAlphaPremultipliedFirst,
	// and kCGImageAlphaPremultipliedLast, with a few other oddball image kinds are supported
	// The images on input here are likely to be png or jpeg files
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
    
	// Build a bitmap context that's the size of the thumbRect
	CGContextRef bitmap = CGBitmapContextCreate(
                                                NULL,
                                                thumbRect.size.width,		// width
                                                thumbRect.size.height,		// height
                                                CGImageGetBitsPerComponent(imageRef),	// really needs to always be 8
                                                4 * thumbRect.size.width,	// rowbytes
                                                CGImageGetColorSpace(imageRef),
                                                alphaInfo
                                                );
    
	// Draw into the context, this scales the image
	CGContextDrawImage(bitmap, thumbRect, imageRef);
    
	// Get an image from the context and a UIImage
	CGImageRef	ref = CGBitmapContextCreateImage(bitmap);
	UIImage*	result = [UIImage imageWithCGImage:ref];
    
	CGContextRelease(bitmap);	// ok if NULL
	CGImageRelease(ref);
    
	return result;
}



-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self setButtonTitle:@"Save"];
}

//function for choose image from file or use camera 
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)originalImage editingInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    };
    CGSize size2 = CGSizeMake(90, 90);
    UIImage *resizedImage=[Utility imageWithImage:image scaledToSize:size2];
    self.displayImageView.image = resizedImage;
    [self dismissModalViewControllerAnimated:YES];
    [self setButtonTitle:@"Save"];
}

- (IBAction)chooseFormFilePressed:(id)sender 
{
    UIImagePickerController *picker=[self setUpPicker];
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentModalViewController:picker animated:YES];
    
}

- (IBAction)takePhotoPressed:(id)sender 
{
    UIImagePickerController *picker=[self setUpPicker];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentModalViewController:picker animated:YES];
}


//By default, the name of a place is unique, so it will notify user
//the name is same and if user still choose to save the place it will replace
//the original place
-(BOOL)checkIfNameIsUnique:(NSString *)name
{
    compeltion_block_t queryBlock;
    __block id result = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    queryBlock = ^(UIManagedDocument *context){
        result = [MyPlace checkIfPlaceExistWithName:name inManagedObjectContext:context.managedObjectContext];
        dispatch_semaphore_signal(sema);
    };
    [MainMapViewController performBlock:queryBlock];
    while(dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]; 
    }
    dispatch_release(sema);
    if(result)return NO;
    else return YES;
}

-(void)saveNewPlace:(UIBarButtonItem *)button
{

    if([button.title isEqualToString:@"Save"]){

        dispatch_queue_t downloadQueue = dispatch_queue_create("My Place downloader", NULL);
        dispatch_async(downloadQueue, ^{
            if(self.myPlace){//update now save or replace
                self.myPlace.placename = self.nameTextField.text;
                self.myPlace.address = self.addressTextField.text;
                NSData *imageData = UIImagePNGRepresentation(self.displayImageView.image);
                self.myPlace.imageData = imageData;
                //need to be save
            }else{
                NSMutableDictionary *myPlaceDictionary = [NSMutableDictionary dictionary];
                [myPlaceDictionary setValue:self.nameTextField.text forKey:@"placeName"];
                [myPlaceDictionary setValue:self.addressTextField.text forKey:@"address"];
                if(self.myWayPoint){
                    [myPlaceDictionary setValue:self.myWayPoint.latitude forKey:@"latitude"];
                    [myPlaceDictionary setValue:self.myWayPoint.longitude forKey:@"longitude"];
                    [myPlaceDictionary setValue:self.myWayPoint.altitude forKey:@"altitude"];
                }else{
                    [myPlaceDictionary setValue:self.bump_latitude forKey:@"latitude"];
                    [myPlaceDictionary setValue:self.bump_longitude forKey:@"longitude"];
                    [myPlaceDictionary setValue:self.bump_altitude forKey:@"altitude"];
                }
                NSData *imageData = UIImagePNGRepresentation(self.displayImageView.image);
                [myPlaceDictionary setValue:imageData forKey:@"imageData"];
                compeltion_block_t saveBlock;
                saveBlock = ^(UIManagedDocument *context){
                    self.myPlace = [MyPlace addMyPlaceWith:myPlaceDictionary inManagedObjectContext:context.managedObjectContext];
                };
                [MainMapViewController performBlock:saveBlock];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.navigationItem.rightBarButtonItem = button;
                [MainMapViewController saveManagedDocument];
                [self setButtonTitle:@"Edit"];
            });
            
        });
        dispatch_release(downloadQueue);
       
    }else if([button.title isEqualToString:@"Edit"]){
        [self setButtonTitle:@"Save"];
    }
}

- (IBAction)savePressed:(id)sender 
{
    if(!self.bumpNotificationView.isHidden){
        [self showOrHideBumpNotificationView];
    }
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    if([button.title isEqualToString:@"Edit"]){
        [self setButtonTitle:@"Save"];
        return;
    }
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] 
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spinner startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    int previousVCIndex = [self.navigationController.viewControllers 
                           indexOfObject:self.navigationController.topViewController]-1;
    
    id previousController = [self.navigationController.viewControllers 
                             objectAtIndex:previousVCIndex];
    //if the previous view controller is favourite place TVC which means user want to edit a 
    //existed place, so we do not need to send user notification
    if(![previousController isKindOfClass:[FavouritePlaceViewController class]] && 
           ![self checkIfNameIsUnique:self.nameTextField.text]){//send notification
        NSString *message = @"This place name has already existed. Do you want to replace it?";
        UIAlertView *alertView = [[UIAlertView alloc]
                                    initWithTitle:@"Duplicate Name"
                                    message:message
                                    delegate:self
                                    cancelButtonTitle:@"Cancle"
                                    otherButtonTitles:@"Yes", nil];
        [alertView show];
        self.navigationItem.rightBarButtonItem = button;
    }else{
        [self saveNewPlace:(UIBarButtonItem *)sender];
    }
}



//format the coordinate string for the data received through bump
-(NSString *)getCoordinateStringWithLatitude:(double)latitude Longitude:(double)longitude
{
    NSString *longitudeStr = nil;
    NSString *latitudeStr = nil;
    if(longitude>0)longitudeStr=@"N";
    else longitudeStr = @"S";
    
    if(latitude>0)latitudeStr=@"E";
    else latitudeStr = @"W";
    // NSString 
    NSString *cor = [NSString stringWithFormat:@"%0.3f°%@  %0.3f°%@",longitude,
                     longitudeStr,latitude,latitudeStr];
    return cor;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                {//Place Name
                    if(self.myPlace){
                        self.nameTextField.text = self.myPlace.placename;
                        UIFont *myBoldSystemFontForName = [ UIFont systemFontOfSize: 15.0 ];
                        self.nameTextField.font = myBoldSystemFontForName;
                    }else{
                        if(!self.nameTextField.text){
                            self.nameTextField.text = @"click here to change name";
                        }
                    }
                    break;
                }
                case 1:
                {//Address
                    if(self.myPlace){
                        self.addressTextField.text = self.myPlace.address;
                    }else{
                        CLLocation *location = [Utility getCurrentLocationWithLatitude:self.myWayPoint.latitude
                                                                           andLonitude:self.myWayPoint.longitude];
                        call_back_block setTextField;
                        setTextField = ^(NSString *addressStr){
                            self.addressTextField.text = addressStr;
                        };
                        [Utility addressForLocation:location withBlock:setTextField];
                    }
                    break;
                }
                case 2:
                {//Altitude
                    double altitude;
                    if(self.myPlace){
                        altitude = [self.myPlace.altitude doubleValue];
                    }else{
                        altitude = [self.myWayPoint.altitude doubleValue];
                    }
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.3f feet",altitude];
                    break;
                }
                case 3:
                {//Coordinate
                    double longitude = 0;
                    double latitude = 0;
                    if(self.myWayPoint){
                        longitude = [self.myWayPoint.longitude doubleValue];
                        latitude = [self.myWayPoint.latitude doubleValue];
                    }else{
                        longitude = [self.myPlace.longitude doubleValue];
                        latitude = [self.myPlace.latitude doubleValue];
                    }
                    cell.detailTextLabel.text = [self getCoordinateStringWithLatitude:latitude Longitude:longitude];
                    break;
                }
                case 4:
                {
                    if(self.myPlace){
                        self.displayImageView.image = [UIImage imageWithData:self.myPlace.imageData];
                    }
                }
            }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark -set region monitor and set alarm

-(void)setRegionMonitor:(double)time_interval
{
    CLLocationManager *locationManager = [MainMapViewController getLocationManager];
    if(!locationManager){
        NSLog(@"Have not initialize location manager!");
        return;
    }
    else{
        CLLocationCoordinate2D baltimoreCoordinate=CLLocationCoordinate2DMake([self.myPlace.latitude doubleValue], [self.myPlace.longitude doubleValue]);
        int regionRadius=500;
        if(regionRadius>locationManager.maximumRegionMonitoringDistance)
        {
            regionRadius=locationManager.maximumRegionMonitoringDistance;
        }
        CLRegion *baltimoreRegion=[[CLRegion alloc] initCircularRegionWithCenter:baltimoreCoordinate radius:regionRadius identifier:@"RegionMonitor"];
        [locationManager startMonitoringForRegion:baltimoreRegion      
                                  desiredAccuracy:kCLLocationAccuracyBest];
        NSMutableDictionary *alarmDic = [MainMapViewController getAlarmDictionary];
        if(!self.myPlace)return;
        NSString *key = [NSString stringWithFormat:@"%f_%f", [self.myPlace.latitude doubleValue],[self.myPlace.longitude doubleValue]];
        [alarmDic setObject:[NSNumber numberWithDouble:time_interval] forKey:key];

        
    }
}


- (void) alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Cancel"]) return;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    if(!textField){//duplicate name notification
        UIBarButtonItem *button = self.navigationItem.rightBarButtonItem;
        [self saveNewPlace:button];
    }else{
        double time_interval = [textField.text doubleValue]*60*60;
        [self setRegionMonitor:time_interval];
    }
    
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section ==0 && indexPath.row == 5){
        if(self.savingState){
            [self setAlarmClick];
        }else{//Show Notification
            NSString *message = @"You need to save current place before you bump it!";
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Cannot Bump" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
    }
}



#pragma configure bumpNotification view 

-(UILabel *)notificationForBump
{
    if(!_notificationForBump)
    {
        _notificationForBump = [[UILabel alloc]init];
        _notificationForBump.frame = CGRectMake(10,5,(self.view.bounds.size.width)/2,50);
        _notificationForBump.backgroundColor = [UIColor clearColor];
        UIFont *myBoldSystemFontForName = [ UIFont systemFontOfSize:15.0];
        _notificationForBump.font = myBoldSystemFontForName;
        _notificationForBump.opaque = NO;
        _notificationForBump.textColor = [UIColor whiteColor];
        _notificationForBump.text = @"Bump you phone!...";
    }
    return _notificationForBump;
}



-(UIImageView *)bumpNotificationView
{
    if(!_bumpNotificationView){
        _bumpNotificationView = [[UIImageView alloc] init];
        _bumpNotificationView.frame = CGRectMake(0,(self.view.frame.size.height-50),(self.view.frame.size.width),75);
        _bumpNotificationView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
        _bumpNotificationView.opaque = NO;
        _bumpNotificationView.layer.cornerRadius = 7;
        _bumpNotificationView.hidden = YES;
        _bumpNotificationView.userInteractionEnabled = YES;
        
        [_bumpNotificationView addSubview:self.notificationForBump];
        [_bumpNotificationView addSubview:self.spinner];
        [self.spinner startAnimating];
    }
    return _bumpNotificationView;
}

-(UIActivityIndicatorView *)spinner
{
    if(!_spinner){
        _spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _spinner.frame = CGRectMake((self.view.bounds.size.width-70), 10, 50, 50);
    }
    return _spinner;
}


-(void)showOrHideBumpNotificationView
{
    [self.view addSubview:self.bumpNotificationView];
    if(!self.bumpNotificationView.isHidden)
    {//hide the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionReveal;
        transition.subtype = kCATransitionFromBottom;
        [self.bumpNotificationView.layer addAnimation:transition forKey:nil];
        self.bumpNotificationView.hidden=YES;
    }else{//show the view
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFromTop;
        [self.bumpNotificationView.layer addAnimation:transition forKey:nil];
        self. bumpNotificationView.hidden = NO;
    }
}

-(void)configureSuccessSound
{
    NSString *successPath = [[NSBundle mainBundle] pathForResource:@"success" ofType:@"wav"];
    NSURL *successURL = [NSURL fileURLWithPath:successPath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)successURL, &_successSound);
}

- (IBAction)bumpToPlay:(id)sender {
    
    
    if(self.savingState){
        [self showOrHideBumpNotificationView];
    }else{//Show Notification
        NSString *message = @"You need to save current place before you bump it!";
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Cannot Bump" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    
    BumpMatchBlock bmb;
    bmb = ^(BumpChannelID channel){
        NSString *user = [[BumpClient sharedClient] userIDForChannel:channel];
        self.notificationForBump.text =[@"Matched with user:" stringByAppendingString:user];
        [[BumpClient sharedClient] confirmMatch:YES onChannel:channel];
    };
    
    BumpChannelConfirmedBlock bccb;
    bccb = ^(BumpChannelID channel){
        NSString *user = [[BumpClient sharedClient] userIDForChannel:channel];
        self.notificationForBump.text =[NSString stringWithFormat:@"Channel with %@ confirmed", user];
        //send shared data
        NSData *myData = [self serialize];
        if(myData==nil)return;
        [[BumpClient sharedClient] sendData:myData toChannel:channel];
    };
    
    BumpDataReceivedBlock bdrb;
    bdrb = ^(BumpChannelID channel, NSData *data){
        if(data == nil)return;
        NSString *user = [[BumpClient sharedClient] userIDForChannel:channel];
        self.notificationForBump.text =[NSString stringWithFormat:@"Data received from %@", user];
        //deal with data received 
        [self deserializeData:data];
    };
    
    BumpConnectionStateChangedBlock bcscb;
    bcscb = ^(BOOL connected){
        if(connected){
            self.notificationForBump.text = @"Bump connected...";
        }else{
            self.notificationForBump.text = @"Bump disconnected...";
            [[BumpClient sharedClient]connect];
        }
    };
    
    BumpEventBlock beb;
    beb = ^(bump_event event){
        switch(event){
            case BUMP_EVENT_BUMP:
                self.notificationForBump.text = @"Bump detected.";
                break;
            case BUMP_EVENT_NO_MATCH:
                self.notificationForBump.text = @"No match! Try again!";
                break;
        }
    };

    [BumpUtility configureBumpWithsetMatchBlock:bmb setChannelConfirmedBlock:bccb setDataReceivedBlock:bdrb setConnectionStateChangedBlock:bcscb setBumpEventBlock:beb];

    
    
}

#pragma mark serilize data
-(NSData *)serialize
{
    if(!self.myPlace){
        NSLog(@"This is wrong! myPlace is empty!");
        return nil;
    }
    NSMutableDictionary *myDict = [NSMutableDictionary dictionary];
    [myDict setValue:self.nameTextField.text forKey:@"placename"];
    [myDict setValue:self.addressTextField.text forKey:@"address"];
    [myDict setValue:self.myPlace.altitude  forKey:@"altitude"];
    [myDict setValue:self.myPlace.latitude forKey:@"latitude"];
    [myDict setValue:self.myPlace.longitude forKey:@"longitude"];
    [myDict setValue:self.myPlace.imageData forKey:@"imageData"];
    NSData *serializedDara = [NSKeyedArchiver archivedDataWithRootObject:myDict];
    return serializedDara;
}

-(void)deserializeData:(NSData *) myData
{
    AudioServicesPlaySystemSound(self.successSound);
    NSDictionary *myDict = [NSKeyedUnarchiver unarchiveObjectWithData:myData];
    //set placeName
    self.nameTextField.text = [myDict valueForKey:@"placename"];
    
    //set address
    self.addressTextField.text = [myDict valueForKey:@"address"];
    
    //set altitude
    double altitude = [(NSNumber *)[myDict valueForKey:@"altitude"] doubleValue];
    NSIndexPath *pathForAltitude = [NSIndexPath indexPathForRow:2 inSection:0];
    [self.tableView cellForRowAtIndexPath:pathForAltitude].detailTextLabel.text = [NSString stringWithFormat:@"%0.3f feet", altitude];
    
    //set coordinate
    NSIndexPath *pathForCoordination = [NSIndexPath indexPathForRow:3 inSection:0];
    double latitude = [(NSNumber *)[myDict valueForKey:@"latitude"] doubleValue];
    double longitude = [(NSNumber *)[myDict valueForKey:@"longitude"] doubleValue];
    NSString *coordinateStr = [self getCoordinateStringWithLatitude:latitude Longitude:longitude];
    [self.tableView cellForRowAtIndexPath:pathForCoordination].detailTextLabel.text = coordinateStr;
    
    //set imageData
    NSData *imageData = [myDict valueForKey:@"imageData"];
    self.displayImageView.image = [UIImage imageWithData:imageData];
    
    //Configure these data in MyWayPoint
    //When we save a place from a wayPoint all things we need is latitude, longitude and altitude
    //Anything else is got from class property (like textfield.text)
    if(self.myWayPoint){
        self.myWayPoint.latitude = [myDict valueForKey:@"latitude"];
        self.myWayPoint.longitude = [myDict valueForKey:@"longitude"];
        self.myWayPoint.altitude = [myDict valueForKey:@"altitude"];
    }else{
        self.bump_altitude = [myDict valueForKey:@"altitude"];
        self.bump_latitude = [myDict valueForKey:@"latitude"];
        self.bump_longitude = [myDict valueForKey:@"longitude"];
    }
    

    
    //reset myPlace because this place card does not exist in database,
    //we will save it as a new waypoint
    self.myPlace = nil;
    [self setButtonTitle:@"Save"];
    //[[BumpClient sharedClient] disconnect];
    
}




- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark -- life cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.addressTextField.borderStyle = UITextBorderStyleNone;
    self.nameTextField.borderStyle = UITextBorderStyleNone;
    UIFont *myBoldSystemFontForName = [ UIFont italicSystemFontOfSize: 13.0 ];
    self.nameTextField.font = myBoldSystemFontForName;
    UIFont *myBoldSystemFontForAddr = [ UIFont systemFontOfSize: 13.0 ];
    self.addressTextField.font = myBoldSystemFontForAddr;
    self.addressTextField.textColor = [UIColor darkGrayColor];
    //set text field
    self.addressTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.addressTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.addressTextField.textAlignment = UITextAlignmentLeft;
    self.addressTextField.keyboardType = UIKeyboardTypeDefault;
    self.addressTextField.returnKeyType = UIReturnKeyDone;
    self.addressTextField.clearButtonMode = UITextFieldViewModeNever;
    self.addressTextField.delegate = self;
    
    
    self.nameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.nameTextField.textAlignment = UITextAlignmentLeft;
    self.nameTextField.keyboardType = UIKeyboardTypeDefault;
    self.nameTextField.returnKeyType = UIReturnKeyDone;
    self.nameTextField.clearButtonMode = UITextFieldViewModeNever;
    self.nameTextField.delegate = self;
    
    self.addressTextField.userInteractionEnabled = NO;
    self.nameTextField.userInteractionEnabled = NO;
    self.fromFileButton.userInteractionEnabled = NO;
    self.takePhotoButton.userInteractionEnabled = NO;
    //[self monitorShake];
    
    //set saving state value
    int previousVCIndex = [self.navigationController.viewControllers 
                           indexOfObject:self.navigationController.topViewController]-1;
    
    id previousController = [self.navigationController.viewControllers 
                             objectAtIndex:previousVCIndex];
    if([previousController isKindOfClass:[FavouritePlaceViewController class]])
    {
        self.savingState = YES;
    }
    else self.savingState = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.myPlace = nil;
}
- (void)viewDidUnload {
    if([BumpClient sharedClient]){
        [[BumpClient sharedClient]disconnect];
    }
    [self setNameTextField:nil];
    [self setAddressTextField:nil];
    [self setDisplayImageView:nil];
    [self setFromFileButton:nil];
    [self setTakePhotoButton:nil];
    [super viewDidUnload];
}
@end
