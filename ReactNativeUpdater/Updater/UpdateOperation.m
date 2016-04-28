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
        _message = [dic getStringValueForKey:@"message" defaultValue:@""];
        _code = [dic getIntValueForKey:@"code" defaultValue:0];
        _error =[dic objectForKey:@"error"];
    }
    return self;
}
@end
