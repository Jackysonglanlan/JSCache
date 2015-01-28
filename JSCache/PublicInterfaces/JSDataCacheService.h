//
//  TTDataCacheService.h
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "JSCachedData.h"

#import "SynthesizeSingleton.h"

@interface JSCacheRefresher : NSObject
@property(nonatomic,copy) void (^dbOperationDidFinishBlock)(void);

// dataList is Array of NSDictionary
-(void)addToCache:(NSArray*)dataList needSyncToDB:(BOOL)needSyncToDB;

// If there is a category exists, this method will insert the data into it
// If there isn't, it will create a new one in cache AND in DB
// dataList is Array of NSDictionary
-(void)insertToCache:(NSArray*)dataList;

@end

// Use this class to manange App's Cache
@interface JSDataCacheService : NSObject
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(JSDataCacheService);

#pragma mark get

-(NSTimeInterval)getRefreshTime:(NSString*)cateName;

-(JSCachedData*)getAndRefreshSingleCachedData:(NSString*)cateName entityId:(NSString*)entityId
                               cacheRefresher:(void (^)(JSCacheRefresher *refresher))refreshBlock
                     refreshIntervalInSeconds:(NSTimeInterval)interval;

-(NSArray*)getAndRefreshCachedData:(NSString*)cateName cacheRefresher:(void (^)(JSCacheRefresher *refresher))refresher
                    entityIdGetter:(NSString* (^)(NSDictionary *data))entityIdGetter refreshIntervalInSeconds:(NSTimeInterval)interval;

-(NSArray*)getCachedData:(NSString*)cateName;

-(JSCachedData*)getCachedDataOfEntityId:(NSString*)entityId;

-(NSDictionary*)getCachedData:(NSString*)cateName entityId:(NSString*)entityId;

#pragma mark add

-(void)addSingleDataToCache:(NSString*)cateName entityId:(NSString*)entityId
                       data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

-(void)insertSingleDataToCache:(NSString*)cateName entityId:(NSString*)entityId atIndex:(NSUInteger)index
                          data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

#pragma mark update

-(void)updateCachedDataOnly:(NSString*)cateName dataList:(NSArray*)dataList entityIdGetter:(NSString* (^)(NSDictionary *data))entityIdGetter;

-(void)updateCachedData:(NSString*)entityId data:(NSDictionary*)data needSyncToDB:(BOOL)needSyncToDB;

#pragma mark delete

// Clean all cached data
-(void)cleanCache:(BOOL)needSyncToDB;

-(void)deleteCachedData:(NSString *)cateName needSyncToDB:(BOOL)needSyncToDB;

-(void)deleteCachedDataOnly:(NSString*)cateName entityId:(NSString*)entityId;

-(void)deleteCachedDataInAllCategory:(NSString*)entityId needSyncToDB:(BOOL)needSyncToDB;

@end
