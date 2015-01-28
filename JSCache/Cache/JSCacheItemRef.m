//
//  TTCacheItemRef.m
//  TianTian
//
//  Created by Song Lanlan on 13-11-6.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "JSCacheItemRef.h"

#import "JSShortHand.h"

@implementation JSCacheItemRef
@synthesize cateName, entityId;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"cateName", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"entityId", @"@\"NSString\"")
                   )

- (void)dealloc{
  JS_releaseSafely(cateName);
  JS_releaseSafely(entityId);
  [super dealloc];
}

@end
