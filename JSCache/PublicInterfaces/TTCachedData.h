//
//  TTCachedData.h
//  TianTian
//
//  Created by Song Lanlan on 13-11-8.
//  Copyright (c) 2013年 tiantian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTCachedData : NSObject

@property(nonatomic,readonly) NSTimeInterval refreshTime;

@property(nonatomic,readonly) NSDictionary *data;

- (id)initWithData:(NSDictionary *)data refreshTime:(NSTimeInterval)refreshTime;

@end
