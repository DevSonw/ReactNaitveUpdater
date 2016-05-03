//
//  UpdaterConfig.h
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReactNativeUpdater.h"
#import "NSDictionaryAdditions.h"

@interface UpdaterConfig : NSObject

-(instancetype)initWithDic:(NSDictionary *)dic;

@property (nonatomic,copy)NSString *deviceVersion;//设备型号
@property (nonatomic,copy)NSString *appVersion;//应用版本
@property (nonatomic,copy)NSString *bundleVersion;//bundle版本
@property (nonatomic,copy)NSString *patchVersion;//补丁版本
@property (nonatomic,copy)NSString *md5;//MD5
@property (nonatomic,copy)NSString *desc;//配置描述信息
@property (nonatomic,copy)NSString *date;//更新日期
@property (nonatomic,copy)NSString *type;//升级类型

@end

