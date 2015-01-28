//
//  TTCacheItem.m
//  TianTian
//
//  Created by Song Lanlan on 13-10-21.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import "JSCacheItem.h"

#import "JSShortHand.h"

@implementation JSCacheItem
@synthesize origJsonData,entityId,data,refreshTimestamp;

DECLARE_PROPERTIES(
                   DECLARE_PROPERTY(@"origJsonData", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"entityId", @"@\"NSString\""),
                   DECLARE_PROPERTY(@"refreshTimestamp", @"@\"NSTimeInterval\"")
                   )

+(NSArray*)transients{
  return @[@"data"];
}

+(JSCacheItem*)findItemOfEntityId:(NSString*)entityId{
  return (JSCacheItem*)[JSCacheItem findFirstByCriteria:@"where entity_id = '%@'",entityId];
}

- (void)dealloc{
  JS_releaseSafely(origJsonData);
  JS_releaseSafely(entityId);
  JS_releaseSafely(data);
  [super dealloc];
}

-(NSDictionary *)data{
  // lazy calculation
  if (data.count == 0){
      NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[origJsonData dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:0 error:nil];
      JS_STUB_STANDARD_SETTER(data, dic);
  }
  return data;
}

@end
