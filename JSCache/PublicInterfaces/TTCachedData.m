//
//  TTCachedData.m
//  TianTian
//
//  Created by Song Lanlan on 13-11-8.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "TTCachedData.h"

#import "JSShortHand.h"

@implementation TTCachedData
@synthesize refreshTime, data;

- (id)initWithData:(NSDictionary *)d refreshTime:(NSTimeInterval)time{
  self = [super init];
  if (self) {
    data = [d retain];
    refreshTime = time;
  }
  return self;
}

- (void)dealloc{
  JS_releaseSafely(data);
  [super dealloc];
}

@end
