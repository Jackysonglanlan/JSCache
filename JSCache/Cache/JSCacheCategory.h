//
//  TTCacheCategory.h
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "SQLitePersistentObject.h"
#import "JSCacheItem.h"

@interface JSCacheCategory : SQLitePersistentObject

@property(nonatomic,retain) NSString *name;
@property(nonatomic,assign) NSTimeInterval refreshTimestamp;// seconds since 1970

-(NSArray*)getRawDataList;

-(void)removeAllItems;

// Sync all cached item to DB, this is a Lazy Calculation strategy
-(void)saveItems;

// This method will ONLY add data into cache, it will NOT sync the data to DB
-(void)addItemFromRawData:(NSDictionary*)rawData entityId:(NSString*)entityId;

// This method will ONLY add data into cache, it will NOT sync the data to DB
-(void)addItemFromRawData:(NSDictionary*)rawData entityId:(NSString*)entityId atIndex:(NSUInteger)index;

// Add item to cache is actually add a ref record
-(void)addItem:(JSCacheItem*)item;

// Remove item is actually remove the ref record
-(void)removeItemByEntityId:(NSString*)entityId;

// return array of TTCacheItem
-(NSArray*)cachedItems;

@end
