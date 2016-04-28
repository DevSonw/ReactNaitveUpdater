//
//  UpdateOperation.h
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/27.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionaryAdditions.h"

@interface UpdateOperation : NSObject

-(instancetype)initWithDic:(NSDictionary *)dic;

@property(nonatomic,strong)NSString *message;

@property(nonatomic,assign)NSInteger code;

@property(nonatomic,strong)NSError *error;

@end
