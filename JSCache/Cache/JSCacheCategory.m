//
//  TTCacheCategory.m
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "JSCacheCategory.h"
#import "JSCacheCateItem.h"
#import "JSCacheItem.h"
#import "JSCacheItemPool.h"

#import "JSShortHand.h"

@implementation JSCacheCategory{  
  // array of JSCacheCateItem
  NSMutableArray *itemRefs;
  
  // pool
  JSCacheItemPool *itemPool;
}
@synthesize name,refreshTimestamp;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"name", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"refreshTimestamp", @"@\"NSTimeInterval\"")
                   )

- (void)dealloc{
  JS_releaseSafely(name);
  JS_releaseSafely(itemRefs);
  [super dealloc];
}

- (id)init{
  self = [super init];
  if (self) {
    itemRefs = [NSMutableArray new];
    itemPool = [JSCacheItemPool sharedInstance];
  }
  return self;
}

#pragma mark private

-(void)addItem:(JSCacheItem*)item withData:(NSDictionary*)data atIndex:(NSUInteger)index{
  [self addItem:item atIndex:index];
  [itemPool addOrUpdateItem:item data:data needSyncToDB:NO];// no need to sync to DB
}

-(void)addItem:(JSCacheItem *)item atIndex:(NSUInteger)index{
  JSCacheCateItem *ref = [JSCacheCateItem new];
  ref.cateName = name;
  ref.entityId = item.entityId;
  [itemRefs insertObject:ref atIndex:index];
  [ref release];
}

#pragma mark public

-(void)removeAllItems{
  [itemRefs removeAllObjects];
}

-(void)saveItems{
  NSMutableArray *idList = [NSMutableArray arrayWithCapacity:itemRefs.count];

  // save refs
    for (JSCacheCateItem *ref in itemRefs) {
        [idList addObject:ref.entityId];
        [ref save];
    }
  
  // update items in DB
  [itemPool syncCacheItemsToDB:idList];
}

-(void)addItemFromRawData:(NSDictionary*)rawData entityId:(NSString*)entityId{
  [self addItemFromRawData:rawData entityId:entityId atIndex:itemRefs.count];
}

-(void)addItemFromRawData:(NSDictionary*)rawData entityId:(NSString*)entityId atIndex:(NSUInteger)index{
  // find item in pool first
  JSCacheItem *item = [itemPool getItemOfEntityId:entityId];
  
  // already in pool, use it
  if (item) {
    [self addItem:item withData:rawData atIndex:index];
    return;
  }
  
  // not in pool, create a new one
  
  item = [JSCacheItem new];
  item.entityId = entityId;
  [self addItem:item withData:rawData atIndex:index];
  [item release];
}

-(void)addItem:(JSCacheItem*)item{
  [self addItem:item atIndex:itemRefs.count];
}

-(void)removeItemByEntityId:(NSString*)entityId{
    JSCacheCateItem *r = nil;
    for (JSCacheCateItem *ref in itemRefs) {
        if ([ref.entityId isEqualToString:entityId]){
            r = ref;
            break;
        }
    }

    if (!r) return;
    [itemRefs removeObject:r];
}

-(NSArray*)cachedItems{
  return [itemPool getItemsInRefList:itemRefs];
}

-(NSArray*)getRawDataList{
    NSArray *cachedItems = [self cachedItems];
    
    NSMutableArray *rawDataList = [NSMutableArray arrayWithCapacity:cachedItems.count];
    
    for (JSCacheItem *item in cachedItems) {
        NSDictionary *data = item.data;// this is a lazy operation
        if (data) {
            [rawDataList addObject:data];
        }
    }
    return rawDataList;
}

@end
