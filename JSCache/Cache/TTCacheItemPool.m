//
//  TTCacheItemPool.m
//  TianTian
//
//  Created by Song Lanlan on 13-11-6.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "TTCacheItemPool.h"
#import "SQLiteInstanceManager.h"

@implementation TTCacheItemPool{
  // [entityId -> TTCacheItem]
  NSMutableDictionary *pool;
}
SYNTHESIZE_SINGLETON_FOR_CLASS(TTCacheItemPool);

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

-(TTCacheItem*)getItemOfEntityId:(NSString*)entityId{
  // read cache first
  TTCacheItem *item = pool[entityId];
  
  if (item){
    return item;
  }
  
  // not in cache

  // find in DB
  item = [TTCacheItem findItemOfEntityId:entityId];
  
  // if in DB
  if (item) {    
    // sync to cache
    [self addOrUpdateItemRefreshTimestamp:item needSyncToDB:NO];
  }
  
  return item;
}

-(NSArray*)getItemsInRefList:(NSArray*)itemRefList{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:itemRefList.count];
    
    for (TTCacheItemRef *ref in itemRefList) {
        TTCacheItem *item = [self getItemOfEntityId:ref.entityId];
        if (item) {
            [items addObject:item];
        }
    }
    
  return items;
}

-(void)syncCacheItemsToDB:(NSArray *)entityIdList{
    for (NSString *entityId in entityIdList) {
        TTCacheItem *item = pool[entityId];
        // if found, sync to DB
        [item save];
    }
}

-(void)addOrUpdateItem:(TTCacheItem *)item data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB{
  if (!item) return;
  
  item.data = data;
    
    NSString *dataJsonStr = [[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:0 error:nil]
                                                   encoding:NSUTF8StringEncoding] autorelease];
  item.origJsonData = dataJsonStr;
  [self addOrUpdateItemRefreshTimestamp:item needSyncToDB:needSyncToDB];
}

-(void)addOrUpdateItemRefreshTimestamp:(TTCacheItem*)item needSyncToDB:(BOOL)needSyncToDB{
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
                                                           [TTCacheItem tableName],entityId]];
}

-(void)clean{
  [pool removeAllObjects];
}

@end
