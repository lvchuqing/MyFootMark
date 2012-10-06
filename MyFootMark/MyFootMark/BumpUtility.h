//
//  BumpUtility.h
//  MyFootMark
//
//  Created by Chuqing Lu on 6/5/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BumpClient.h"

@interface BumpUtility : NSObject

#define BUMPAPIKEY @"affb49bde0414abf8bae58db8b60b961"
#define USERNAME @"keren"
+(void)configureBumpWithsetMatchBlock:(BumpMatchBlock)bmb
             setChannelConfirmedBlock:(BumpChannelConfirmedBlock)bccb
                 setDataReceivedBlock:(BumpDataReceivedBlock)bdrb
       setConnectionStateChangedBlock:(BumpConnectionStateChangedBlock)bcscb
                    setBumpEventBlock:(BumpEventBlock)beb;

//This function is used for test
+ (void) configureBump;


@end
