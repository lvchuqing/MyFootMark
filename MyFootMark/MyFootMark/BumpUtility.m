//
//  BumpUtility.m
//  MyFootMark
//
//  Created by Chuqing Lu on 6/5/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "BumpUtility.h"

@implementation BumpUtility


+(void)configureBumpWithsetMatchBlock:(BumpMatchBlock)bmb
             setChannelConfirmedBlock:(BumpChannelConfirmedBlock)bccb
                 setDataReceivedBlock:(BumpDataReceivedBlock)bdrb
       setConnectionStateChangedBlock:(BumpConnectionStateChangedBlock)bcscb
                    setBumpEventBlock:(BumpEventBlock)beb
{
    
    [BumpClient configureWithAPIKey:BUMPAPIKEY andUserID:USERNAME];
    
    [[BumpClient sharedClient] setMatchBlock:bmb];
    
    [[BumpClient sharedClient] setChannelConfirmedBlock:bccb];
    
    [[BumpClient sharedClient] setDataReceivedBlock:bdrb];
    
    [[BumpClient sharedClient] setConnectionStateChangedBlock:bcscb];
    
    [[BumpClient sharedClient] setBumpEventBlock:beb];

}


+ (void) configureBump {
    [BumpClient configureWithAPIKey:BUMPAPIKEY andUserID:USERNAME];
    
    [[BumpClient sharedClient] setMatchBlock:^(BumpChannelID channel) { 
        NSLog(@"Matched with user: %@", [[BumpClient sharedClient] userIDForChannel:channel]); 
        [[BumpClient sharedClient] confirmMatch:YES onChannel:channel];
    }];
    
    [[BumpClient sharedClient] setChannelConfirmedBlock:^(BumpChannelID channel) {
        NSLog(@"Channel with %@ confirmed.", [[BumpClient sharedClient] userIDForChannel:channel]);
        [[BumpClient sharedClient] sendData:[[NSString stringWithFormat:@"Hello, world!"] dataUsingEncoding:NSUTF8StringEncoding]
                                  toChannel:channel];
    }];
    
    [[BumpClient sharedClient] setDataReceivedBlock:^(BumpChannelID channel, NSData *data) {
        NSLog(@"Data received from %@: %@", 
              [[BumpClient sharedClient] userIDForChannel:channel], 
              [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding]);
    }];
    
    [[BumpClient sharedClient] setConnectionStateChangedBlock:^(BOOL connected) {
        if (connected) {
            NSLog(@"Bump connected...");
        } else {
            NSLog(@"Bump disconnected...");
        }
    }];
    
    [[BumpClient sharedClient] setBumpEventBlock:^(bump_event event) {
        switch(event) {
            case BUMP_EVENT_BUMP:
                NSLog(@"Bump detected.");
                break;
            case BUMP_EVENT_NO_MATCH:
                NSLog(@"No match.");
                break;
        }
    }];
}




@end
