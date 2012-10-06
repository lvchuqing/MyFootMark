//
//  BaseTableViewController.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/4/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "BaseTableViewController.h"
#import <MessageUI/MessageUI.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <Twitter/Twitter.h>

@interface BaseTableViewController ()<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation BaseTableViewController


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



-(void)pushNotificationWithContent:(NSString *)content
{
    UILocalNotification *locationNotification = [[UILocalNotification alloc] init];
    locationNotification.alertBody=content;
    locationNotification.alertAction=@"Ok";
    locationNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:locationNotification];
    
}
#pragma mark -set alarm

-(void)setAlarmClick
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Set time interval for alert"
                              message:@"Please enter how many hours you want to spend here:"
                              delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Ok", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    /* Display a numerical keypad for this text field */
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeDecimalPad;
    [alertView show];
}

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


#pragma mark - sendEmail


// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayMailComposerSheetWithContent:(NSString *)content withTitle:(NSString *)title withImage:(UIImage *)image
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject:title];
    if(image){
        NSData *myData = UIImagePNGRepresentation(image);
        [picker addAttachmentData:myData mimeType:@"image/jpeg" fileName:@"attachment"];
    }
	// Fill out the email body text
	NSString *emailBody = content;
	[picker setMessageBody:emailBody isHTML:NO];
	[self presentModalViewController:picker animated:YES];
}



// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the 
// message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller 
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
	// Notifies users about errors associated with the interface
    if(result == MFMailComposeResultFailed)
    {
        [self pushNotificationWithContent:@"Mail sending failed"];
    }
	[self dismissModalViewControllerAnimated:YES];
}



- (void)sendEmailWithContent:(NSString *)content withTitle:(NSString *)title withImage:(UIImage *)image
{
    // The MFMailComposeViewController class is only available in iPhone OS 3.0 or later. 
	// So, we must verify the existence of the above class and provide a workaround for devices running 
	// earlier versions of the iPhone OS. 
	// We display an email composition interface if MFMailComposeViewController exists and the device 
	// can send emails.	Display feedback message, otherwise.
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
	if (mailClass != nil) {
        //[self displayMailComposerSheet];
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail]) {
			[self displayMailComposerSheetWithContent:content withTitle:title withImage:image];
		}
		else {
            [self pushNotificationWithContent:@"Device not configured to send mail."];

		}
	}
	else{
        [self pushNotificationWithContent:@"Device not configured to send mail."];
	}
}


#pragma mark -- send SMS message

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    //We do not notify this message
    if (result == MessageComposeResultSent)
    {
        NSLog(@"Message sent.");
    }
    else if (result == MessageComposeResultFailed)
    {
        NSLog(@"Message Failed to Send!");
    }
    [self dismissModalViewControllerAnimated:YES];
}


- (void)sendSMSWithContent:(NSString *)content
{
    if ([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController *messageVC = [[MFMessageComposeViewController alloc] init];
        messageVC.messageComposeDelegate = self;    
        messageVC.body = content;
        [self presentModalViewController:messageVC animated:YES];
    }
    else
    {
        [self pushNotificationWithContent:@"Error, Text Messaging Unavailable"];
    }
}


#pragma mark -- send tweet
- (void)sendTweetWithContent:(NSString *)content withImagePath:(NSString *)path
{
    if ([TWTweetComposeViewController canSendTweet])
    {
        TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
        [tweetSheet setInitialText:content];
        if(path){
           /* if (self.imageString)
            {
                [tweetSheet addImage:[UIImage imageNamed:self.imageString]];
            }
            
            if (self.urlString)
            {
                [tweetSheet addURL:[NSURL URLWithString:self.urlString]];
            }*/
        }
	    [self presentModalViewController:tweetSheet animated:YES];
    }
    else
    {
        [self pushNotificationWithContent:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"];
    }
    
}





@end
