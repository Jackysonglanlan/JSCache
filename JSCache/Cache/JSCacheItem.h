//
//  TTCacheItem.h
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "SQLitePersistentObject.h"

@interface JSCacheItem : SQLitePersistentObject

@property(nonatomic,retain) NSString *origJsonData;
@property(nonatomic,retain) NSString *entityId;

/**
 * *Transient* property. It will *not* be saved in DB.
 *
 * NSDictionary of the origJsonData string.
 * When called getter, it will cache the data for later use.
 * The getter method of this property is a lazy op, it will perform the json convertion when be called.
 */
@property(nonatomic,retain) NSDictionary *data;

@property(nonatomic,assign) NSTimeInterval refreshTimestamp;// seconds since 1970

+(JSCacheItem*)findItemOfEntityId:(NSString*)entityId;

@end
