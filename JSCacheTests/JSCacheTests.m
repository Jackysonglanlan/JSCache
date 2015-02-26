//
//  TestComTests.m
//  TestComTests
//
//  Created by jackysong on 14-11-11.
//  Copyright (c) 2014年 cmge. All rights reserved.
//

#import "AbstractTests.h"

#import "JSDataCacheService.h"

#import "SQLiteInstanceManager.h"
#import "JSCacheCateItem.h"
#import "JSCacheCategory.h"
#import "JSCacheItem.h"

@interface JSCacheTests : AbstractTests

@end

@implementation JSCacheTests{
    JSDataCacheService *service;
}

-(void)cleanDBTable:(NSString*)tableName{
    if ([[SQLiteInstanceManager sharedManager] tableExists:tableName]) {
        [[SQLiteInstanceManager sharedManager] executeUpdateSQL:[NSString stringWithFormat:@"delete from %@ ",tableName]];
    }
}

-(void)before{
    service = [JSDataCacheService sharedInstance];
    [service retain];
    
    service.dbFullPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"aaa.sqlite"];
    
    // connect database
    [[SQLiteInstanceManager sharedManager] database];
    
    [self cleanDBTable:[JSCacheCategory tableName]];
    [self cleanDBTable:[JSCacheCateItem tableName]];
    [self cleanDBTable:[JSCacheItem tableName]];
}

-(void)after{
    [service release];
    service = nil;
}

-(void)testSave{
    JSCacheCategory *cate = [JSCacheCategory new];
    cate.name = @"name";
    cate.refreshTimestamp = [[NSDate date] timeIntervalSince1970];
    
    [[SQLiteInstanceManager sharedManager] doInTransactionAsync:^{
        for (int i=0; i<5; i++) {
            JSCacheItem *item = [JSCacheItem new];
            item.origJsonData = [@"json str...." stringByAppendingFormat:@"%d",i];
            item.entityId = @"110e86baee8f136a683da65e93a50e7";
            
            [cate addItem:item];
        }
        
        [cate save];
        [cate saveItems];
    }
                                                      didFinish:^{
                                                      }];
}

-(void)testCache{
    NSString *cateName = @"main_page";
    NSString *testEntityId = @"110e86baee8f136a683da65e93a50e7";
    
    NSArray *dataList = [service getAndRefreshCachedData:cateName
                                          cacheRefresher:^(JSCacheRefresher *refresher) {
                                              // simulate async invocation
                                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                  [NSThread sleepForTimeInterval:2];
                                                  
                                                  NSMutableArray *arr = [NSMutableArray array];
                                                  for (int i=0; i<5; i++) {
                                                      [arr addObject:@{@"key1": @1, @"key2":@2, @"postId":testEntityId}];
                                                  }
                                                  [refresher createInCache:arr needSyncToDB:YES];
                                                  
                                                  [self finishedAsyncOperation];
                                                  
                                              });
                                          }
                                          entityIdGetter:^NSString *(NSDictionary *data) {
                                              return data[@"postId"];
                                          }
                                refreshIntervalInSeconds:0];
    
    // first use, no data in cache and DB
    assertThat(dataList, nilValue());
    
    [self beginAsyncOperationWithTimeout:60];
    // async invocation finished
    
    // use again
    dataList = [service getAndRefreshCachedData:cateName
                                 cacheRefresher:^(JSCacheRefresher *refresher) {
                                     // simulate 2nd async invocation
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                         [NSThread sleepForTimeInterval:2];
                                         
                                         NSMutableArray *arr = [NSMutableArray array];
                                         for (int i=0; i<3; i++) {
                                             [arr addObject:@{@"keyAgain": @1, @"postId":testEntityId}];
                                         }
                                         [refresher insertToCache:arr];
                                         [self finishedAsyncOperation];
                                     });
                                 }
                                 entityIdGetter:^NSString *(NSDictionary *data) {
                                     return data[@"postId"];
                                 }
                       refreshIntervalInSeconds:0];
    
    // here should be the data added at the 1st time
    assertThatInt(dataList.count, equalToInt(5));
    assertThat(dataList[0][@"postId"], is(testEntityId));
    
    // NOT in DB
    
    int count = [JSCacheItem countByCriteria:@"where cate_name = '%@'",cateName];
    assertThatInt(count, equalToInt(0));
    
    [self beginAsyncOperationWithTimeout:60];
    // 2nd async invocation finished
    
    int cateItemCountShouldBe = 5+3;
    
    dataList = [service getCachedData:cateName];
    assertThatInt(dataList.count, equalToInt(cateItemCountShouldBe));
    assertThat(dataList[0][@"postId"], is(testEntityId));
    
    NSDictionary *data = [service getCachedData:cateName entityId:testEntityId];
    assertThat(data[@"postId"], is(testEntityId));
    
    
    /*
     [self beginAsyncOperation];
     
     // add new category
     NSString *newCate = @"chengdu_page";
     dataList = [service getAndRefreshCachedData:newCate
     cacheRefresher:^(TTCacheRefresher *refresher) {
     [Executors dispatchAsync:DISPATCH_QUEUE_PRIORITY_DEFAULT task:^{
     [NSThread sleepForTimeInterval:1];
     
     NSMutableArray *arr = [NSMutableArray array];
     for (int i=0; i<3; i++) {
     [arr addObject:@{@"c1": @(i), @"c2":@(i), @"photoId":[@"110e86baee8f136a683da65e93a50e" stringByAppendingFormat:@"%d",i]}];
     }
     [refresher addToCache:arr needSyncToDB:YES];
     [self finishedAsyncOperation];
     }];
     }
     entityIdGetter:^NSString *(NSDictionary *data) {
     return data[@"photoId"];
     }
     refreshIntervalInSeconds:0];
     
     assertThat(dataList, nilValue());
     
     [self waitForAsyncOperationOrTimeoutWithDefaultInterval];
     // new category added
     
     dataList = [service getCachedData:newCate];
     assertThatInt(dataList.count, equalToInt(3));
     assertThat(dataList[0][@"photoId"], is(@"110e86baee8f136a683da65e93a50e0"));
     
     // old data still there
     NSDictionary *oldData = [service getCachedData:cateName entityId:testEntityId];
     assertThat(oldData[@"key1"], is(@1));
     
     TTCacheCategory *cate = (TTCacheCategory*)[TTCacheCategory findFirstByCriteria:@"where name = '%@'", newCate];
     assertThatInt([cate cachedItems].count, equalToInt(3));
     
     // delete
     testEntityId = @"110e86baee8f136a683da65e93a50e0";
     [service deleteCachedData:newCate entityId:testEntityId needSyncToDB:YES];
     oldData = [service getCachedData:newCate entityId:testEntityId];
     assertThat(oldData, nilValue());
     */
}

-(void)testUpdate{
    NSString *testEntityId = @"11111";
    
    NSString *cateName1 = @"aaa";
    [service getAndRefreshCachedData:cateName1
                      cacheRefresher:^(JSCacheRefresher *refresher) {
                          NSMutableArray *arr = [NSMutableArray array];
                          
                          for (int i=0; i<5; i++) {
                              [arr addObject:@{@"keyA": @(i), @"postId":testEntityId}];
                          }
                          [refresher createInCache:arr needSyncToDB:YES];
                      }
                      entityIdGetter:^NSString *(NSDictionary *data) {
                          return data[@"postId"];
                      }
            refreshIntervalInSeconds:0];
    
    NSString *cateName2 = @"bbb";
    [service getAndRefreshCachedData:cateName2
                      cacheRefresher:^(JSCacheRefresher *refresher) {
                          NSMutableArray *arr = [NSMutableArray array];
                          
                          for (int i=0; i<5; i++) {
                              [arr addObject:@{@"keyB": @(i), @"postId":testEntityId}];
                          }
                          [refresher insertToCache:arr];// TODO how to do in DB if you insert an item with same id in memory?
                      }
                      entityIdGetter:^NSString *(NSDictionary *data) {
                          return data[@"postId"];
                      }
            refreshIntervalInSeconds:0];
    
    // update data
    [service updateCachedData:testEntityId data:@{@"newKey": @"newValue"} needSyncToDB:YES];
    
    // should update all the data whose entityId is testEntityId
    NSDictionary *data1 = [service getCachedData:cateName1 entityId:testEntityId];
    NSDictionary *data2 = [service getCachedData:cateName2 entityId:testEntityId];
    
    assertThat(data1[@"newKey"], notNilValue());
    assertThat(data1[@"newKey"], is(@"newValue"));
    assertThat(data1[@"newKey"], is(data2[@"newKey"]));
    
    // also updated DB
    NSArray *items = [JSCacheItem findByCriteria:@"where entity_id = '%@'", testEntityId];
    assertThatInt(items.count, equalToInt(1));
    NSDictionary *dataInDB = [(JSCacheItem*)items[0] data];
    assertThat(dataInDB[@"newKey"], notNilValue());
    assertThat(dataInDB[@"newKey"], is(@"newValue"));
}

-(void)testDelete{
    NSString *testEntityId1 = @"11111";
    NSString *testEntityId2 = @"22222";
    NSString *cateName = @"aaa";
    
    // deleteCachedData:needSyncToDB:
    
    [service getAndRefreshCachedData:cateName
                      cacheRefresher:^(JSCacheRefresher *refresher) {
                          NSMutableArray *arr = [NSMutableArray array];
                          [arr addObject:@{@"keyA": @1, @"postId":testEntityId1}];
                          [arr addObject:@{@"keyB": @2, @"postId":testEntityId2}];
                          [refresher createInCache:arr needSyncToDB:YES];
                      }
                      entityIdGetter:^NSString *(NSDictionary *data) {
                          return data[@"postId"];
                      }
            refreshIntervalInSeconds:0];
    
    [service deleteCachedData:cateName needSyncToDB:YES];
    
    NSInteger countInDB = [JSCacheCategory countByCriteria:@"where name = '%@'",cateName];
    assertThatInt(countInDB, equalToInt(0));
    countInDB = [JSCacheItem countByCriteria:@"where cate_name = '%@'",cateName];
    assertThatInt(countInDB, equalToInt(0));
    
    NSArray *dataList = [service getCachedData:cateName];
    
    assertThat(dataList, nilValue());
    
    // deleteCachedDataOnly:entityId:
    
    [service getAndRefreshCachedData:cateName
                      cacheRefresher:^(JSCacheRefresher *refresher) {
                          NSMutableArray *arr = [NSMutableArray array];
                          [arr addObject:@{@"keyA": @1, @"postId":testEntityId1}];
                          [arr addObject:@{@"keyB": @2, @"postId":testEntityId2}];
                          [refresher createInCache:arr needSyncToDB:YES];
                      }
                      entityIdGetter:^NSString *(NSDictionary *data) {
                          return data[@"postId"];
                      }
            refreshIntervalInSeconds:0];
    
    [service deleteCachedDataOnly:cateName entityId:testEntityId1];
    
    countInDB = [JSCacheItem countByCriteria:@"where entity_id = '%@'",testEntityId1];
    assertThatInt(countInDB, equalToInt(1)); // still in DB
    countInDB = [JSCacheItem countByCriteria:@"where entity_id = '%@'",testEntityId2];
    assertThatInt(countInDB, equalToInt(1));
    
    dataList = [service getCachedData:cateName];
    
    assertThatInt(dataList.count, equalToInt(1));
    NSDictionary *data = [service getCachedData:cateName entityId:testEntityId2];
    assertThat(data[@"keyB"], is(@2));
    
    // deleteCachedData:needSyncToDB:
    
    [service getAndRefreshCachedData:cateName
                      cacheRefresher:^(JSCacheRefresher *refresher) {
                          NSMutableArray *arr = [NSMutableArray array];
                          [arr addObject:@{@"keyA": @1, @"postId":testEntityId1}];
                          [arr addObject:@{@"keyB": @2, @"postId":testEntityId2}];
                          [refresher createInCache:arr needSyncToDB:YES];
                      }
                      entityIdGetter:^NSString *(NSDictionary *data) {
                          return data[@"postId"];
                      }
            refreshIntervalInSeconds:0];
    
    // add another
    NSString *newCateName = @"bbb";
    [service getAndRefreshCachedData:newCateName
                      cacheRefresher:^(JSCacheRefresher *refresher) {
                          NSMutableArray *arr = [NSMutableArray array];
                          [arr addObject:@{@"keyA": @1, @"postId":testEntityId1}];// with the same id
                          [arr addObject:@{@"keyB": @2, @"postId":testEntityId2}];// with the same id
                          [refresher createInCache:arr needSyncToDB:YES];
                      }
                      entityIdGetter:^NSString *(NSDictionary *data) {
                          return data[@"postId"];
                      }
            refreshIntervalInSeconds:0];
    
    [service deleteCachedDataInAllCategory:testEntityId1 needSyncToDB:YES];
    
    countInDB = [JSCacheItem countByCriteria:@"where entity_id = '%@'",testEntityId1];
    assertThatInt(countInDB, equalToInt(0));
    
    dataList = [service getCachedData:cateName];
    assertThatInt(dataList.count, equalToInt(1));// delete 1
    data = [service getCachedData:cateName entityId:testEntityId2];
    assertThat(data[@"keyB"], is(@2));
    
    dataList = [service getCachedData:newCateName];
    assertThatInt(dataList.count, equalToInt(1));// delete 1
    data = [service getCachedData:newCateName entityId:testEntityId2];
    assertThat(data[@"keyB"], is(@2));
    
}

-(void)testClean{
    NSString *testEntityId = @"adsfsdfsf";
    
    // add
    for (int i=0; i<10; i++) {
        [service getAndRefreshCachedData:[NSString stringWithFormat:@"cate-%d",i]
                          cacheRefresher:^(JSCacheRefresher *refresher) {
                              [refresher setDbOperationDidFinishBlock:^{
                              }];
                              
                              NSMutableArray *arr = [NSMutableArray array];
                              for (int i=0; i<10; i++) {
                                  [arr addObject:@{@"keyA": @1, @"postId":[testEntityId stringByAppendingFormat:@"%d",i]}];
                              }
                              [refresher createInCache:arr needSyncToDB:YES];
                          }
                          entityIdGetter:^NSString *(NSDictionary *data) {
                              return data[@"postId"];
                          }
                refreshIntervalInSeconds:0];
    }
    
    //
    
    [service cleanCache:YES];
    for (int i=0; i<10; i++) {
        NSArray *dataList = [service getCachedData:[@"cate-" stringByAppendingFormat:@"%d",i]];
        assertThat(dataList, nilValue());
    }
    
}

@end
