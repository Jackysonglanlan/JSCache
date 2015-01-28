//
//  TTCacheItemPool.h
//  TianTian
//
//  Created by Song Lanlan on 13-11-6.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

#import "JSCacheItem.h"
#import "JSCacheItemRef.h"

@interface JSCacheItemPool : NSObject
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(JSCacheItemPool);

-(BOOL)isItemExists:(NSString*)entityId;

// this method will sync item to cache automatically if the item is in DB but NOT in cache
-(JSCacheItem*)getItemOfEntityId:(NSString*)entityId;

-(NSArray*)getItemsInRefList:(NSArray*)itemRefList;

-(void)syncCacheItemsToDB:(NSArray *)entityIdList;

-(void)addOrUpdateItem:(JSCacheItem *)item data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

-(void)removeItem:(NSString*)entityId needSyncToDB:(BOOL)needSyncToDB;

-(void)clean;

@end
