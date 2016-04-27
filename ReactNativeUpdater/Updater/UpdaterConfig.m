//
//  UpdaterConfig.m
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import "UpdaterConfig.h"

@implementation UpdaterConfig
-(instancetype)initWithDic:(NSDictionary *)dic {
    self = [super init];
    if (self) {
        _deviceVersion = [dic objectForKey:@"deviceVersion"];
        _appVersion = [dic objectForKey:@"appVersion"];
        _bundleVersion = [dic objectForKey:@"bundleVersion"];
        _patchVersion = [dic objectForKey:@"patchVersion"];
        _md5 = [dic objectForKey:@"md5"];
        _desc = [dic objectForKey:@"desc"];
        _date = [dic objectForKey:@"date"];
    }
    return self;
}
@end
