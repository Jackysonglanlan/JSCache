//
//  JSCacheCateItem.h
//  TianTian
//
//  Created by Song Lanlan on 13-11-6.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "SQLitePersistentObject.h"

@interface JSCacheCateItem : SQLitePersistentObject

@property(nonatomic,retain) NSString *cateName;
@property(nonatomic,retain) NSString *entityId;

@end
