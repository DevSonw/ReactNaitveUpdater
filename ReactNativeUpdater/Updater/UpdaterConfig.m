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
        _deviceVersion = [dic getStringValueForKey:@"deviceVersion" defaultValue:@""];
        _appVersion = [dic getStringValueForKey:@"appVersion" defaultValue:@""];
        _bundleVersion = [dic getStringValueForKey:@"bundleVersion" defaultValue:@""];
        _patchVersion = [dic getStringValueForKey:@"patchVersion" defaultValue:@""];
        _md5 = [dic getStringValueForKey:@"md5" defaultValue:@""];
        _desc = [dic getStringValueForKey:@"desc" defaultValue:@""];
        _date = [dic getStringValueForKey:@"date" defaultValue:@""];
        _type = [dic getStringValueForKey:@"type" defaultValue:@""];
    }
    return self;
}
@end
