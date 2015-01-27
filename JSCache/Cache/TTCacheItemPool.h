//
//  TTCacheItemPool.h
//  TianTian
//
//  Created by Song Lanlan on 13-11-6.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

#import "TTCacheItem.h"
#import "TTCacheItemRef.h"

@interface TTCacheItemPool : NSObject
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(TTCacheItemPool);

-(BOOL)isItemExists:(NSString*)entityId;

// this method will sync item to cache automatically if the item is in DB but NOT in cache
-(TTCacheItem*)getItemOfEntityId:(NSString*)entityId;

-(NSArray*)getItemsInRefList:(NSArray*)itemRefList;

-(void)syncCacheItemsToDB:(NSArray *)entityIdList;

-(void)addOrUpdateItem:(TTCacheItem *)item data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

-(void)removeItem:(NSString*)entityId needSyncToDB:(BOOL)needSyncToDB;

-(void)clean;

@end
