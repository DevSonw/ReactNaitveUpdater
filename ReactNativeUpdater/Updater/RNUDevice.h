//
//  POCDevice.h
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef RNU_DEBUG
#if DEBUG
#define RNU_DEBUG 1
#else
#define RNU_DEBUG 0
#endif
#endif


@interface RNUDevice : NSObject

+(void)setEnv:(id)env forKey:(NSString *)key;

@end
