//
//  ReactNativeUpdater.h
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

//
/*
 config 文件，明文保存json文件
 bundle 文件 diff 文件， 加密，压缩
 升级完成以后只保存加密后的bundle 文件。
 
 //使用指南
 1.首先到获取到最新的配置文件，对比是否需要升级。
 2.根据最新配置文件信息，是否请求最新的JSBunlde.
 3.应用最新的bundel
 4.加入回滚机制，把上一版的Bundle 放入history目录。附带版本信息。
 */

#import <Foundation/Foundation.h>
#import "UpdaterConfig.h"
#import "UpdateOperation.h"

typedef NS_ENUM(NSUInteger, ReactNativeUpdateType) {
    ReactNativeUpdateRollBack = 0,
    ReactNativeUpdateNotUpdate = 1, //不升级
    ReactNativeUpdateEntiretyUpdate = 2,
    ReactNativeUpdatePartUpdate, //Default
    ReactNativeUpdatePatchUpdate,
};

typedef NS_ENUM(NSUInteger, ReactNativeUpdateApplyType) {
    ReactNativeUpdateApplyNextLaunch = 1, //Default
    ReactNativeUpdateApplyImmediately,
};


@interface ReactNativeUpdater : NSObject

@property (nonatomic,assign)ReactNativeUpdateType updateType;//更新类型
@property (nonatomic,assign)ReactNativeUpdateApplyType applyType;//应用类型
@property (nonatomic,strong)NSURL *defaultJSCodeLocation;//MainBundle中的Bundle文件
@property (nonatomic,strong)NSURL *defaultConfigFile;//默认的配置文件
@property (nonatomic,strong)NSURL *currentJSCodeLocation;//当前JS文件
@property (nonatomic,strong)NSURL *currentConfigFile;//当前配置文件


+ (instancetype)sharedInstance;
    /*
         ------>> 传入两个Url，自动控制升级
     */
- (void)updateWithConfigUrl:(NSString *)configUrlString bundleUrl:(NSString *)bundleUrlString Success:(void (^)(UpdateOperation *opreation))success failure:(void (^)(UpdateOperation *opreation))failure;
@end
