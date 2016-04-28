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

@property (nonatomic,strong)NSString *deviceVersion;//设备型号
@property (nonatomic,strong)NSString *appVersion;//应用版本
@property (nonatomic,strong)NSString *bundleVersion;//bundle版本
@property (nonatomic,strong)NSString *patchVersion;//补丁版本
@property (nonatomic,strong)NSString *md5;//MD5
@property (nonatomic,strong)NSString *desc;//配置描述信息
@property (nonatomic,strong)NSString *date;//更新日期

@end

