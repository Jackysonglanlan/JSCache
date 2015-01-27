//
//  TTCacheItem.h
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "SQLitePersistentObject.h"

@interface TTCacheItem : SQLitePersistentObject

@property(nonatomic,retain) NSString *origJsonData;
@property(nonatomic,retain) NSString *entityId;
@property(nonatomic,retain) NSDictionary *data;
@property(nonatomic,assign) NSTimeInterval refreshTimestamp;// seconds since 1970

+(TTCacheItem*)findItemOfEntityId:(NSString*)entityId;

@end
