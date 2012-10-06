//
//  CoreDataHelper.m
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import "CoreDataHelper.h"


@implementation CoreDataHelper

+(void)useSharedMangedDocument:(UIManagedDocument *)managedDoc
                toExecuteBlock:(compeltion_block_t)completionBlock
{
    /*if(!timeNow)timeNow = [NSDate date];
    else{
        NSTimeInterval interval = [timeNow timeIntervalSinceDate:[NSDate date]];
        if(abs(interval)<60)return;
    }*/
    if(!managedDoc){
        NSLog(@"Error, DocumentManaged have not been created");
        return;
    }
    
    //we have already create file on disk when we init it
    if(managedDoc.documentState & UIDocumentStateInConflict){
        NSLog(@"in conflict");
    }else if(managedDoc.documentState & UIDocumentStateSavingError){
        NSLog(@"in conflict");
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:[managedDoc.fileURL path]]){
        //create the document here
        [managedDoc saveToURL:managedDoc.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            completionBlock(managedDoc);
        }];
    }
    if(managedDoc.documentState == UIDocumentStateClosed){
        //exists on disk, but we need to open it
        [managedDoc openWithCompletionHandler:^(BOOL success){
            completionBlock(managedDoc);
        }];
    }else if(managedDoc.documentState == UIDocumentStateNormal){
        //already open and ready to use
        completionBlock(managedDoc);
    }
}



@end
