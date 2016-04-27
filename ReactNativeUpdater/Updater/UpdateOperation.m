//
//  UpdateOperation.m
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/27.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import "UpdateOperation.h"

@implementation UpdateOperation
-(instancetype)initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _message = [dic objectForKey:@"message"];
        _code = [[dic objectForKey:@"code"]integerValue];
        _error = [dic objectForKey:@"error"];
    }
    return self;
}
@end
