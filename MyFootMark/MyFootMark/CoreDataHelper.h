//
//  CoreDataHelper.h
//  TrackFootmark
//
//  Created by Chuqing Lu on 6/2/12.
//  Copyright (c) 2012 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^compeltion_block_t) (UIManagedDocument *dataBaseManager);
#define DEFAULTDATABASENAME @"Track FootPrints"


@interface CoreDataHelper : NSObject


+(void)useSharedMangedDocument:(UIManagedDocument *)managedDoc 
                toExecuteBlock:(compeltion_block_t)completionBlock;


@end
