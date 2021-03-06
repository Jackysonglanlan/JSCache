//
//  TTDataCacheService.h
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "JSCachedData.h"

#import "SynthesizeSingleton.h"

/**
 * Responsible for refreshing the cache (Create and Update ops)
 */
@interface JSCacheRefresher : NSObject

/**
 * Create an record in cache, if there's one exist with the same cateName, it will be *removed*.
 * @param dataList Array of NSDictionary
 */
-(void)createInCache:(NSArray*)dataList needSyncToDB:(BOOL)needSyncToDB;

/**
 * If there is a category exists, this method will insert the data into it
 * If there isn't, it will create a new one in cache AND in DB
 * @param dataList Array of NSDictionary
 */
-(void)insertToCache:(NSArray*)dataList;

@end

/**
 * Main class of JSCache
 */
@interface JSDataCacheService : NSObject
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(JSDataCacheService);

// The underlining DB JSCache will use to store data
@property(nonatomic,retain) NSString *dbFullPath;

#pragma mark Create

-(void)addSingleDataToCate:(NSString*)cateName entityId:(NSString*)entityId
                      data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

-(void)insertSingleDataToCate:(NSString*)cateName entityId:(NSString*)entityId atIndex:(NSUInteger)index
                         data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

#pragma mark Read

-(NSTimeInterval)getRefreshTime:(NSString*)cateName;

-(JSCachedData*)getAndRefreshSingleCachedDataInCate:(NSString*)cateName entityId:(NSString*)entityId
                                     cacheRefresher:(void (^)(JSCacheRefresher *refresher))refreshBlock
                           refreshIntervalInSeconds:(NSTimeInterval)interval;

-(NSArray*)getAndRefreshCachedDataInCate:(NSString*)cateName cacheRefresher:(void (^)(JSCacheRefresher *refresher))refresher
                          entityIdGetter:(NSString* (^)(NSDictionary *data))entityIdGetter
                refreshIntervalInSeconds:(NSTimeInterval)interval;

-(NSArray*)getCachedDataInCate:(NSString*)cateName;

-(JSCachedData*)getCachedDataOfEntityId:(NSString*)entityId;

-(NSDictionary*)getCachedDataInCate:(NSString*)cateName entityId:(NSString*)entityId;

#pragma mark Update

-(void)updateCachedDataInMemoryInCate:(NSString*)cateName dataList:(NSArray*)dataList
                       entityIdGetter:(NSString* (^)(NSDictionary *data))entityIdGetter;

-(void)updateCachedDataWithId:(NSString*)entityId data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

#pragma mark Delete

// Clean all cached data
-(void)cleanCache:(BOOL)needSyncToDB;

-(void)deleteAllCachedDataInCate:(NSString *)cateName needSyncToDB:(BOOL)needSyncToDB;

-(void)deleteCachedDataInMemoryInCate:(NSString*)cateName entityId:(NSString*)entityId;

-(void)deleteCachedDataInAllCategoryWithId:(NSString*)entityId needSyncToDB:(BOOL)needSyncToDB;

@end
