//
//  TTDataCacheService.m
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "TTDataCacheService.h"
#import "SQLiteInstanceManager.h"

#import "TTCacheCategory.h"
#import "TTCacheItem.h"
#import "TTCacheItemPool.h"

#import "SynthesizeSingleton.h"

#import "JSShortHand.h"

#pragma mark TTCacheRefresher

@implementation TTCacheRefresher{
  NSMutableDictionary *underlineCache;
  TTCacheItemPool *itemPool;
  NSString *cateName;
  NSString *(^entityIdGetter)(NSDictionary *data);
  
  SQLiteInstanceManager *sqlManager;
}
@synthesize dbOperationDidFinishBlock;

- (id)initWithUnderlineCache:(NSMutableDictionary*)cache cateName:(NSString*)name
              entityIdGetter:(NSString *(^)(NSDictionary *data))getter{
  self = [super init];
  if (self) {
    underlineCache = cache;
    cateName = [name retain];
    entityIdGetter = [getter copy];
    itemPool = [TTCacheItemPool sharedInstance];
    sqlManager = [SQLiteInstanceManager sharedManager];
  }
  return self;
}

- (void)dealloc{
  JS_releaseSafely(cateName);
  JS_releaseSafely(entityIdGetter);
  JS_releaseSafely(dbOperationDidFinishBlock);
  [super dealloc];
}

-(void)addToCache:(NSArray*)dataList needSyncToDB:(BOOL)needSyncToDB{
  if (dataList.count == 0) return;
  
  TTCacheCategory *cate = [TTCacheCategory new];
  cate.name = cateName;
  cate.refreshTimestamp = [[NSDate date] timeIntervalSince1970];
  
  for (NSDictionary *data in dataList) {
    NSString *entityId = entityIdGetter(data);// get entity id
    [cate addItemFromRawData:data entityId:entityId];
  }
  
  // save in cache
  underlineCache[cateName] = cate;
  
  if (needSyncToDB) {
    // refresh DB
    [sqlManager doInTransactionAsync:^{
      [self removeAllCachedDataInDBWithCateName:cateName];
      [self saveDataToDB:cate];
    }
                           didFinish:^{
                             if (dbOperationDidFinishBlock) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     dbOperationDidFinishBlock();
                                 });
                             }
                           }];
  }
  
  [cate release];
}

-(void)insertToCache:(NSArray*)dataList{
  TTCacheCategory *cate = underlineCache[cateName];
  
  // if haven't had category yet, we auto add it
  if (!cate) {
    [self addToCache:dataList needSyncToDB:NO];
  }

  NSMutableArray *itemsNeedSyncToDB = [NSMutableArray arrayWithCapacity:dataList.count];
    for (NSDictionary *data in dataList) {
        NSString *entityId = entityIdGetter(data);// get entity id
        
        // items need sync to DB
        TTCacheItem *item = [itemPool getItemOfEntityId:entityId];
        if (item) {
            item.data = data;// set new data
            [itemsNeedSyncToDB addObject:item];
        }
        
        // if have had category, we insert
        [cate addItemFromRawData:data entityId:entityId];
    }
  
  // transaction batch save
  [sqlManager doInTransactionAsync:^{
      for (TTCacheItem *item in itemsNeedSyncToDB) {
          [itemPool addOrUpdateItem:item data:item.data needSyncToDB:YES];
      }
  }
                         didFinish:^{
                           if (dbOperationDidFinishBlock) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   dbOperationDidFinishBlock();
                               });
                           }
                         }];
}

// save all data of the category into DB
-(void)saveDataToDB:(TTCacheCategory*)cate{
  [cate save];
  [cate saveItems];
}

// remove all data of the category from DB
-(void)removeAllCachedDataInDBWithCateName:(NSString*)name{
  // delete related records in TTCacheCategory table
  if ([sqlManager tableExists:[TTCacheCategory tableName]]) {
    [[TTCacheCategory findFirstByCriteria:@"where name = '%@'",name] deleteObject];
  }

  // delete related records in TTCacheItemRef table
  if ([sqlManager tableExists:[TTCacheItemRef tableName]]) {
    [sqlManager executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ where cate_name = '%@'",
                                                             [TTCacheItemRef tableName], name]];
  }

  // here, we don't delete records in TTCacheItem table, it always there
}

@end

#pragma mark TTDataCacheService

@implementation TTDataCacheService{
  // [cateName -> TTCacheCategory]
  NSMutableDictionary *underlineCache;
  TTCacheItemPool *itemPool;
  SQLiteInstanceManager *sqlManager;
}
SYNTHESIZE_SINGLETON_FOR_CLASS(TTDataCacheService);

- (id)init{
  self = [super init];
  if (self) {
    underlineCache = [NSMutableDictionary new];
    itemPool = [TTCacheItemPool sharedInstance];
    sqlManager = [SQLiteInstanceManager sharedManager];

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanCacheOnly)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
  }
  return self;
}

#pragma mark private

#pragma mark MemoryWarning
-(void)cleanCacheOnly{
  [self cleanCache:NO];
}

-(TTCacheCategory*)findCategoryInDB:(NSString*)cateName{
  TTCacheCategory *cate = (TTCacheCategory*)[TTCacheCategory findFirstByCriteria:@"where name = '%@'", cateName];
  
  if (!cate) return nil;
  
  // load data related to cate
  NSArray *refs =  [TTCacheItemRef findByCriteria:@"where cate_name = '%@' ",cateName];
    for (TTCacheItemRef *ref in refs) {
        [cate addItem: [itemPool getItemOfEntityId:ref.entityId]];
    }
  
  return cate;
}

#pragma mark get

-(NSTimeInterval)getRefreshTime:(NSString*)cateName{
  // find in cache
  TTCacheCategory *cate = underlineCache[cateName];
  
  if (cate) {
    return cate.refreshTimestamp;
  }
  
  // not in cache, find in DB

  cate = [self findCategoryInDB:cateName];
  return cate.refreshTimestamp;
}

-(TTCachedData*)getAndRefreshSingleCachedData:(NSString*)cateName entityId:(NSString*)entityId
                               cacheRefresher:(void (^)(TTCacheRefresher *refresher))refreshBlock
                     refreshIntervalInSeconds:(NSTimeInterval)interval{
  
  // find in cache then DB
  TTCachedData *data = [self getCachedDataOfEntityId:entityId];
  
  if (data) {
    // check whether we need to update data in DB
    if ([[NSDate date] timeIntervalSince1970] - data.refreshTime > interval) {
      TTCacheRefresher *refresher = [[[TTCacheRefresher alloc] initWithUnderlineCache:underlineCache
                                                                             cateName:cateName
                                                                       entityIdGetter:^NSString *(NSDictionary *data) {
                                                                         return entityId;
                                                                       }] autorelease];
      refreshBlock(refresher); // update cache/DB
      // refreshBlock will invoke an async method, so it will return immediately
    }
    
    return data;
  }
  
  // here no data in cache, not in DB, and the newest data haven't return yet
  // we have to return nil
  return nil;
}

-(NSArray*)getAndRefreshCachedData:(NSString*)cateName cacheRefresher:(void (^)(TTCacheRefresher *refresher))refreshBlock
                    entityIdGetter:(NSString* (^)(NSDictionary *data))entityIdGetter refreshIntervalInSeconds:(NSTimeInterval)interval{
  TTCacheCategory *cate = underlineCache[cateName];
  
  // find in cache

  if (cate) {
    // check whether we need to update data in DB
    if ([[NSDate date] timeIntervalSince1970] - cate.refreshTimestamp > interval) {
      TTCacheRefresher *refresher = [[[TTCacheRefresher alloc] initWithUnderlineCache:underlineCache
                                                                             cateName:cateName
                                                                       entityIdGetter:entityIdGetter] autorelease];
      refreshBlock(refresher); // update cache/DB
      // refreshBlock will invoke an async method, so it will return immediately
    }
    
    // here, we return the cached data

    // or, there is no need to update the cache/DB, just return data in cache
    return [cate getRawDataList];
  }
  
  // haven't cached yet
  
  cate = [self findCategoryInDB:cateName];
  
  // if it is't in DB
  if (!cate) {
    TTCacheRefresher *refresher = [[[TTCacheRefresher alloc] initWithUnderlineCache:underlineCache
                                                                           cateName:cateName
                                                                     entityIdGetter:entityIdGetter] autorelease];
    refreshBlock(refresher); // update cache/DB
    // doBusiness will invoke an async method, so it will return immediately
    
    // so, here no data in cache, not in DB, and the newest data haven't return yet
    // we have to return nil
    return nil;
  }

  // in DB, not in Cache

  // add to cache
  underlineCache[cateName] = cate;

  // check whether we need to update data in DB
  if ([[NSDate date] timeIntervalSince1970] - cate.refreshTimestamp > interval) {
    TTCacheRefresher *refresher = [[[TTCacheRefresher alloc] initWithUnderlineCache:underlineCache
                                                                           cateName:cateName
                                                                     entityIdGetter:entityIdGetter] autorelease];
    refreshBlock(refresher); // update cache/DB
    // refreshBlock will invoke an async method, so it will return immediately
  }

  return [cate getRawDataList];
}

-(NSArray*)getCachedData:(NSString*)cateName{
  TTCacheCategory *cate = underlineCache[cateName];
  
  // data is in cache
  return [cate getRawDataList];
  
  // isn't in cache, find in DB
  cate = [self findCategoryInDB:cateName];
  
  // found in DB
  if (cate) {
    // add to Cache
    underlineCache[cateName] = cate;
  }
  
  return [cate getRawDataList];
}

-(TTCachedData*)getCachedDataOfEntityId:(NSString*)entityId{
  TTCacheItem *item = [itemPool getItemOfEntityId:entityId];
  return [[[TTCachedData alloc] initWithData:item.data refreshTime:item.refreshTimestamp] autorelease];
}

-(NSDictionary*)getCachedData:(NSString*)cateName entityId:(NSString*)entityId{
  TTCacheCategory *cate = underlineCache[cateName];
  
  // data is in cache
  if (cate) {
      for (TTCacheItem *item in [cate cachedItems]) {
          if ([item.entityId isEqualToString:entityId])
              return item.data;
      }
  }
  
  // isn't in cache, find in DB
  
  cate = (TTCacheCategory*)[TTCacheCategory findFirstByCriteria:@"where name = '%@'", cateName];
  
  // category not in DB, return nil
  
  if (!cate) return nil;
  
  TTCacheItem *item = [itemPool getItemOfEntityId:entityId];
  
  // item not in DB, return nil

  if (!item) return nil;

  [cate addItem:item];
  
  // add to Cache
  underlineCache[cateName] = cate;
  
  return item.data;
}

#pragma mark add

-(void)addSingleDataToCache:(NSString*)cateName entityId:(NSString*)entityId
                       data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB{
  TTCacheRefresher *refresher = [[[TTCacheRefresher alloc] initWithUnderlineCache:underlineCache
                                                                         cateName:cateName
                                                                   entityIdGetter:^NSString *(NSDictionary *data) {
                                                                     return entityId;
                                                                   }] autorelease];
  [refresher insertToCache:@[data]];
}

-(void)insertSingleDataToCache:(NSString*)cateName entityId:(NSString*)entityId atIndex:(NSUInteger)index
                          data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB{
  TTCacheCategory *cate = underlineCache[cateName];
  if (cate) {
    [cate addItemFromRawData:data entityId:entityId atIndex:index];
    [self updateCachedData:entityId data:data needSyncToDB:needSyncToDB];
  }
}

#pragma mark update

-(void)updateCachedDataOnly:(NSString*)cateName dataList:(NSArray*)dataList entityIdGetter:(NSString* (^)(NSDictionary *data))entityIdGetter{
  TTCacheCategory *cate = underlineCache[cateName];
  if (cate) {
    [cate removeAllItems];
    
      for (NSDictionary *data in dataList) {
          NSString *entityId = entityIdGetter(data);// get entity id
          [cate addItemFromRawData:data entityId:entityId];
          
          [self updateCachedData:entityId data:data needSyncToDB:NO];// don't sync to DB
      }
  }
}

-(void)updateCachedData:(NSString*)entityId data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB{
  TTCacheItem *item = [itemPool getItemOfEntityId:entityId];
  [itemPool addOrUpdateItem:item data:data needSyncToDB:needSyncToDB];
}

#pragma mark delete

-(void)cleanDBTable:(NSString*)tableName{
  if ([[SQLiteInstanceManager sharedManager] tableExists:tableName]) {
    [[SQLiteInstanceManager sharedManager] executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ ",tableName]];
  }
}

-(void)cleanCache:(BOOL)needSyncToDB{
  // clean cache
  [underlineCache removeAllObjects];

  [itemPool clean];
  
  if (!needSyncToDB) return;

  // clean DB
  // TODO there maybe a bug: if someone is inserting the DB, and this method is called in memory_warning, it will crash!
  [sqlManager doInTransactionAsync:^{
    [self cleanDBTable:[TTCacheCategory tableName]];
    [self cleanDBTable:[TTCacheItemRef tableName]];
    [self cleanDBTable:[TTCacheItem tableName]];
  }
                         didFinish:nil];
}

-(void)deleteCachedData:(NSString *)cateName needSyncToDB:(BOOL)needSyncToDB{
  // delete from cache
  [underlineCache removeObjectForKey:cateName];
  
  if (!needSyncToDB) return;
  
  // delete from DB

  [sqlManager doInTransactionAsync:^{
    [sqlManager executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ where name = '%@' ",
                                  [TTCacheCategory tableName], cateName]];
    
    [sqlManager executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ where cate_name = '%@' ",
                                  [TTCacheItemRef tableName], cateName]];    
  }
                         didFinish:nil];

  // here, for we don't know whether other categories have the same items in this deleted category,
  // so we CAN't remove items in TTCacheItemPool and in DB.
}

-(void)deleteCachedDataOnly:(NSString*)cateName entityId:(NSString*)entityId{
  TTCacheCategory *cate = underlineCache[cateName];
  [cate removeItemByEntityId:entityId];
}

-(void)deleteCachedDataInAllCategory:(NSString*)entityId needSyncToDB:(BOOL)needSyncToDB{
  // delete item in all category    
    for (TTCacheCategory *cate in [underlineCache allValues]) {
        [cate removeItemByEntityId:entityId];
    }
  
  // delete item in pool
  [itemPool removeItem:entityId needSyncToDB:needSyncToDB];
  
  if (!needSyncToDB) return;

  // delete from DB

  [sqlManager executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ where entity_id = '%@'",
                                                           [TTCacheItemRef tableName],entityId]];
}




@end
