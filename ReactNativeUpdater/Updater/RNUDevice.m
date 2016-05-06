//
//  POCDevice.m
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import "RNUDevice.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

NSMutableDictionary *kRNUDeviceEnv = nil;

@implementation RNUDevice

+(void)setEnv:(id)env forKey:(NSString *)key{
    [[self getEnv] setObject:env forKey:key];
}

+(id)objectForMainBundleKey:(NSString *)key{
    NSObject *obj = [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
    return obj ? obj : [NSNull null];
}

+(NSMutableDictionary *)getEnv{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIDevice *device = [UIDevice currentDevice];
        NSString *platform = [NSString stringWithFormat:@"%@; %@ %@; %@", device.model, device.systemName, device.systemVersion, [[NSLocale currentLocale] localeIdentifier]];
        BOOL debug = false;
#if RNU_DEBUG
        debug = true;
#endif
        UIScreen *mainScreen = [UIScreen mainScreen];
        NSLocale *currentLocale = [NSLocale currentLocale];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSDictionary *def = @{
                              @"isPad": @([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad),
                              @"platform": platform,
                              @"model": device.model,
                              @"modelName": [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding],
                              @"udid": [device.identifierForVendor UUIDString],
                              @"systemType": @"iOS",
                              @"systemName": device.systemName,
                              @"systemVersion": device.systemVersion,
                              @"localeLanguage": [[NSLocale preferredLanguages] count] ? [[NSLocale preferredLanguages] objectAtIndex:0] : [NSNull null],
                              @"localeCountry": [currentLocale objectForKey:NSLocaleCountryCode] ? [currentLocale objectForKey:NSLocaleCountryCode] : [NSNull null],
                              @"appId": [self objectForMainBundleKey:@"CFBundleIdentifier"],
                              @"appName": [self objectForMainBundleKey:@"CFBundleName"],
                              @"appDisplayName": [self objectForMainBundleKey:@"CFBundleDisplayName"],
                              @"appVersion": [self objectForMainBundleKey:@"CFBundleVersion"],
                              @"appShortVersion": [self objectForMainBundleKey:@"CFBundleShortVersionString"],
                              @"screenScale": @(mainScreen.scale),
                              @"screenWidth": @(mainScreen.bounds.size.width),
                              @"screenHeight": @(mainScreen.bounds.size.height),
                              
                              @"debug": @(debug),
                              };
        kRNUDeviceEnv = [[NSMutableDictionary alloc] initWithDictionary:def];
    });

    return kRNUDeviceEnv;
}

@end
