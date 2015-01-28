//
//  TTCacheItemPool.m
//  TianTian
//
//  Created by Song Lanlan on 13-11-6.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "JSCacheItemPool.h"
#import "SQLiteInstanceManager.h"

@implementation JSCacheItemPool{
  // [entityId -> TTCacheItem]
  NSMutableDictionary *pool;
}
SYNTHESIZE_SINGLETON_FOR_CLASS(JSCacheItemPool);

- (id)init{
  self = [super init];
  if (self) {
    pool = [[NSMutableDictionary alloc] initWithCapacity:50]; // TODO: may change
  }
  return self;
}

-(BOOL)isItemExists:(NSString*)entityId{
  return pool[entityId] != nil;
}

-(JSCacheItem*)getItemOfEntityId:(NSString*)entityId{
  // read cache first
  JSCacheItem *item = pool[entityId];
  
  if (item){
    return item;
  }
  
  // not in cache

  // find in DB
  item = [JSCacheItem findItemOfEntityId:entityId];
  
  // if in DB
  if (item) {    
    // sync to cache
    [self addOrUpdateItemRefreshTimestamp:item needSyncToDB:NO];
  }
  
  return item;
}

-(NSArray*)getItemsInRefList:(NSArray*)itemRefList{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:itemRefList.count];
    
    for (JSCacheCateItem *ref in itemRefList) {
        JSCacheItem *item = [self getItemOfEntityId:ref.entityId];
        if (item) {
            [items addObject:item];
        }
    }
    
  return items;
}

-(void)syncCacheItemsToDB:(NSArray *)entityIdList{
    for (NSString *entityId in entityIdList) {
        JSCacheItem *item = pool[entityId];
        // if found, sync to DB
        [item save];
    }
}

-(void)addOrUpdateItem:(JSCacheItem *)item data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB{
  if (!item) return;
  
  item.data = data;
    
    NSString *dataJsonStr = [[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:0 error:nil]
                                                   encoding:NSUTF8StringEncoding] autorelease];
  item.origJsonData = dataJsonStr;
  [self addOrUpdateItemRefreshTimestamp:item needSyncToDB:needSyncToDB];
}

-(void)addOrUpdateItemRefreshTimestamp:(JSCacheItem*)item needSyncToDB:(BOOL)needSyncToDB{
  if (!item) return;
  
  // add / update cache
  item.refreshTimestamp = [[NSDate date] timeIntervalSince1970];
  pool[item.entityId] = item;
  
  if (!needSyncToDB) return;
  
  // update DB
  [item save];
}

-(void)removeItem:(NSString*)entityId needSyncToDB:(BOOL)needSyncToDB{
  [pool removeObjectForKey:entityId];
  
  if (!needSyncToDB) return;

  [[SQLiteInstanceManager sharedManager] executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ where entity_id = '%@'",
                                                           [JSCacheItem tableName],entityId]];
}

-(void)clean{
  [pool removeAllObjects];
}

@end
