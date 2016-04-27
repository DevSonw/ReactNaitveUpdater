//
//  ReactNativeUpdater.m
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import "ReactNativeUpdater.h"

NSString * const fileTypeConfig = @"configFile";
NSString * const fileTypeJSBundle   = @"jsBundle";

@implementation ReactNativeUpdater

static ReactNativeUpdater *UPDATER_SINGLETON=nil;

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UPDATER_SINGLETON = [[super allocWithZone:NULL] init];
        [UPDATER_SINGLETON defaults];
    });
    return UPDATER_SINGLETON;
}
+ (id) allocWithZone:(NSZone *)zone {
    return [self sharedInstance];
}
+ (id)copyWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}
+ (id)mutableCopyWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}
- (id)copy {
    return [[ReactNativeUpdater alloc] init];
}
- (id)mutableCopy {
    return [[ReactNativeUpdater alloc] init];
}
- (id) init {
    if(UPDATER_SINGLETON){
        return UPDATER_SINGLETON;
    }
    self = [super init];
    return self;
}
- (void)defaults {
    self.updateType = ReactNativeUpdatePartUpdate;
    self.applyType = ReactNativeUpdateApplyNextLaunch;
}

//获取Libray 路径
- (NSString *)libraryDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}
//默认的JSBunlde
- (NSURL *)defaultJSCodeLocation{
    NSURL* defaultJSCodeLocation = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
    return defaultJSCodeLocation;
}
//默认的Config
- (NSURL *)defaultConfigFile{
    NSURL* defaultConfigFile = [[NSBundle mainBundle] URLForResource:@"config" withExtension:@"json"];
    return defaultConfigFile;
}

//获取代码文件&配置文件路径
- (NSString *)codeDirectory {
    NSString* libraryDirectory = [self libraryDirectory];
    NSString *filePathAndDirectory = [libraryDirectory stringByAppendingPathComponent:@"JSCode"];
    NSError *error;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fileManager fileExistsAtPath:filePathAndDirectory isDirectory:&isDir]) {
        if (isDir) {
            return filePathAndDirectory;
        }
    }
    if (![fileManager createDirectoryAtPath:filePathAndDirectory
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error])
    {
        NSLog(@"Create directory error: %@", error);
        return nil;
    }
    return filePathAndDirectory;
}

//获取当前的jsbundle 当前的如果没有，返回默认bundle 中的JS
- (NSURL*)currentJSCodeLocation{
    NSString* currentJSCodeURLString = [[self codeDirectory] stringByAppendingPathComponent:@"main.jsbundle"];
    if (currentJSCodeURLString && [[NSFileManager defaultManager] fileExistsAtPath:currentJSCodeURLString]) {
        self.currentJSCodeLocation = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", currentJSCodeURLString]];
    }
    return self.currentJSCodeLocation ? self.currentJSCodeLocation : self.defaultJSCodeLocation;
}

//获取当前的配置文件,如果没有则返回默认的bundle 中的配置文件
- (NSURL*)currentConfigFile{
    NSString* currentConfigFileString = [[self codeDirectory] stringByAppendingPathComponent:@"config.json"];
    if (currentConfigFileString && [[NSFileManager defaultManager] fileExistsAtPath:currentConfigFileString]) {
        self.currentConfigFile = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", currentConfigFileString]];
    }
    return self.currentConfigFile? self.currentConfigFile : self.defaultConfigFile;
}

/*
 ------>> 传入两个Url，自动控制升级
 */
- (void)updateWithConfigUrl:(NSString *)configUrlString bundleUrl:(NSString *)bundleUrlString Success:(void (^)(UpdateOperation *opreation))success failure:(void (^)(UpdateOperation *opreation))failure {
    //1.首先下载并保存最新的Config文件
    [self downloadLastFileFromUrl:[NSURL URLWithString:configUrlString] fileType:fileTypeConfig completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        UpdaterConfig *config = [[UpdaterConfig alloc]initWithDic:dictionary];
        
        if ([self shouldDownloadUpdateFileWithLastConfig:config]) {
            //如果需下载最新的Bundle file
            [self downloadLastFileFromUrl:[NSURL URLWithString:bundleUrlString] fileType:fileTypeJSBundle completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable responseContent, NSError * _Nullable error) {
                //此时已经确定升级
                //1.校验，解压，
                //2.
                
            }];
        }else{
            //不需要下载最新的bunlde
            NSDictionary *resultDic =[[NSDictionary alloc]initWithObjectsAndKeys:@"不需要更新",@"message", nil];
            failure([[UpdateOperation alloc]initWithDic:resultDic]);
        }
#warning 新bundle写入完成以后才会写入最新的配置文件 配置文件是对Bundle的描述
        //新bundle写入完成以后才会更新config文件
         NSString* filename = [NSString stringWithFormat:@"%@/%@", [self codeDirectory], @"config.json"];
        if ([data writeToFile:filename atomically:YES]) {
            
        }
        
        
        else {
            NSLog(@"[ReactNativeUpdater]: Update save failed - %@.", error.localizedDescription);
        }
    }];
}





/*
 ————-->> 传入两个文件 自动控制升级
 */
- (void)updateWithConfigFile:(NSURL *)configFile bundleFile:(NSURL *)bundleFile Success:(void (^)(UpdateOperation *opreation))success failure:(void (^)(UpdateOperation *opreation))failure {
    
}

//下载文件
- (void)downloadLastFileFromUrl:(NSURL *)downloadUrl fileType:(NSString *)fileType completionHandler:(void (^)(NSData * __nullable responseData, NSURLResponse * __nullable responseContent, NSError * __nullable error))completionHandler {
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 60.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    NSURLSession *session =[NSURLSession sessionWithConfiguration:sessionConfig];
    session.sessionDescription = fileType;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:downloadUrl completionHandler:completionHandler];
    [dataTask resume];
    
}

//对比配置文件 是否下载新的bundle
- (BOOL)shouldDownloadUpdateFileWithLastConfig:(UpdaterConfig *)updateConfig {
    //updatefig为最新服务器上的config,
    //1.首先拿到本地保存的json配置文件
    
    
    return NO;
}


@end