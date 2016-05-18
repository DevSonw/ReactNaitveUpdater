//
//  ReactNativeUpdater.m
//  ReactNativeUpdater
//
//  Created by Hao on 16/4/26.
//  Copyright © 2016年 RainbowColors. All rights reserved.
//

#import "ReactNativeUpdater.h"
#import "CocoaSecurity.h"
#import "ZipArchive.h"
#import "DiffMatchPatch.h"

NSString * const fileTypeConfig = @"configFile";
NSString * const fileTypeJSBundle   = @"jsBundle";
NSString * const zipPassword = @"";
NSString * const MD5Salt = @"";
NSString * const securityHexKey = @"";
NSString * const securityHexIv = @"";

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
- (id)init {
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
//获取Temp 路径
- (NSString *)tempDirectoty {
    return NSTemporaryDirectory();
}
//默认的JSBunlde
- (NSURL *)defaultJSCodeLocation {
    return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
}
//默认的Config
- (NSURL *)defaultConfigFile {
    return [[NSBundle mainBundle] URLForResource:@"config" withExtension:@"json"];
}

//保存临时下载的Bundle和Config文件目录
- (NSString *)bundleTmpDirectory {
    NSString *tmpDirectory = [self tempDirectoty];
    NSString *filePathAndDirectory = [tmpDirectory stringByAppendingPathComponent:@"jstmp"];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
//获取代码文件&配置文件路径
- (NSString *)codeDirectory {
    NSString *libraryDirectory = [self libraryDirectory];
    NSString *filePathAndDirectory = [libraryDirectory stringByAppendingPathComponent:@"jsbundle"];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
//获取上一个版本的JSbundle
- (NSString *)historyDirectory {
    NSString *libraryDirectory = [self libraryDirectory];
    NSString *filePathAndDirectory = [libraryDirectory stringByAppendingPathComponent:@"history"];
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
- (NSURL *)currentJSCodeLocation{
    NSString *currentJSCodeURLString = [[self codeDirectory] stringByAppendingPathComponent:@"main.jsbundle"];
    if (currentJSCodeURLString && [[NSFileManager defaultManager] fileExistsAtPath:currentJSCodeURLString]) {
        self.currentJSCodeLocation = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", currentJSCodeURLString]];
    }
    return self.currentJSCodeLocation ? self.currentJSCodeLocation : self.defaultJSCodeLocation;
}

//获取当前的配置文件,如果没有则返回默认的bundle 中的配置文件
- (NSURL *)currentConfigFile{
    NSString *currentConfigFileString = [[self codeDirectory] stringByAppendingPathComponent:@"config.json"];
    if (currentConfigFileString && [[NSFileManager defaultManager] fileExistsAtPath:currentConfigFileString]) {
        self.currentConfigFile = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", currentConfigFileString]];
    }
    return self.currentConfigFile? self.currentConfigFile : self.defaultConfigFile;
}

//通过文件获得UpdateConfig
- (UpdaterConfig *)updateConfigByConfigFile:(NSURL *)configFile {
    NSData *configData = [NSData dataWithContentsOfURL:configFile];
    NSError *serializaError;
    NSDictionary *confiDic = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingMutableContainers error:&serializaError];
    if (serializaError) {
        return nil;
    }
    UpdaterConfig *config = [[UpdaterConfig alloc]initWithDic:confiDic];
    return config;
}

//对比配置文件 是否下载新的bundle
- (ReactNativeUpdateType)shouldDownloadUpdateFileWithLastConfig:(UpdaterConfig *)updateConfig {
    //updatefig为最新服务器上的config,
    //1.首先拿到本地保存的json配置文件
    //配置文件中如果有升级信息，就直接应用配置文件中的升级规则
    NSURL *currentConfigUrl = [self currentConfigFile];
    UpdaterConfig *currentConfig = [self updateConfigByConfigFile:currentConfigUrl];
    //对比配置文件确定升级规则
    //1.如果APP版本不对， 不升级
    if(updateConfig.appVersion.floatValue!=currentConfig.appVersion.floatValue) {
        return ReactNativeUpdateNotUpdate;
    }
    //升级规则有待完善，可自定规则
    
    
    
    
    
    
    return ReactNativeUpdateNotUpdate;
}

/*
 ------>> 传入两个Url，自动控制升级
 */
- (void)updateWithConfigUrl:(NSString *)configUrlString bundleUrl:(NSString *)bundleUrlString Success:(void (^)(UpdateOperation *opreation))success failure:(void (^)(UpdateOperation *opreation))failure {
    //1.首先下载并保存最新的Config文件在Tmp文件夹
    [self downloadLastFileFromUrl:[NSURL URLWithString:configUrlString] fileType:fileTypeConfig completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            
            return ;
        }
        NSString *congfigTempPath= [[self bundleTmpDirectory]stringByAppendingPathComponent:@"config.json"];
        NSFileManager *mgr = [NSFileManager defaultManager];
        BOOL moveSuc =[mgr moveItemAtPath:location.path toPath:congfigTempPath error:nil];
        NSData *data;
        if (!moveSuc) {
            return;
        }
        data = [NSData dataWithContentsOfFile:congfigTempPath];
        NSError *serializaError;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&serializaError];
        if (serializaError) {
            return ;
        }
        UpdaterConfig *config = [[UpdaterConfig alloc]initWithDic:dictionary];
        ReactNativeUpdateType updateType =[self shouldDownloadUpdateFileWithLastConfig:config];
        //回滚
        if (updateType==ReactNativeUpdateRollBack) {
            BOOL rollbackSuc = [self rollBack];
            if (rollbackSuc) {
                NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"回滚成功",@"message", nil];
                UpdateOperation *result = [[UpdateOperation alloc]initWithDic:dic];
                success(result);
                return;
            }else{
                NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"回滚失败",@"message", nil];
                UpdateOperation *result = [[UpdateOperation alloc]initWithDic:dic];
                failure(result);
                return;
            }
        }
        else if (updateType > 1) {
            //如果需下载最新的Bundle file
            [self downloadLastFileFromUrl:[NSURL URLWithString:bundleUrlString] fileType:fileTypeJSBundle completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                //此时已经确定升级
                //现在完成放到TMP目录
                NSString *zipTempPath = [[self bundleTmpDirectory]stringByAppendingPathComponent:@"bundle.zip"];;
                NSFileManager *mgr = [NSFileManager defaultManager];
                BOOL moveSuc =[mgr moveItemAtPath:location.path toPath:zipTempPath error:nil];
                if (!moveSuc) {
                    return;
                }
                //1.校验
                NSString *fileMd5 = [self generateMD5SignFromFile:zipTempPath];
                BOOL isVaild  =[self checkMD5SignValidWithConfig:config fileMD5:fileMd5];
                if (!isVaild) {
                    return;
                }
                //2.解压 解压后的文件在JSTmp文件夹内
                BOOL unzipSuc = [self unZipFileWithConfig:config zipFile:zipTempPath];
                if (!unzipSuc) {
                    return;
                }
                //3.取到文件
                NSString *sourceFile;
                if (config.type.integerValue==ReactNativeUpdateEntiretyUpdate) {
                    sourceFile = [[self tempDirectoty]stringByAppendingPathComponent:@"main.jsbundle"];
                }else if(config.type.integerValue ==ReactNativeUpdatePartUpdate||config.type.integerValue ==ReactNativeUpdatePatchUpdate){
                    sourceFile = [[self tempDirectoty]stringByAppendingPathComponent:@"bundle.diff"];
                }
                if (sourceFile) {
                    //2.拿到文件后，执行传入文件方法。传入的文件是未解密的文件才temp文件夹内
                    [self updateWithFile:sourceFile updateType:updateType Success:^(UpdateOperation *opreation) {
                        
                        
                        
                        
                        
                        
                        
                    } failure:^(UpdateOperation *opreation) {
                        
                        
                        
                        

                        
                    }];
                }
            }];
        }else{
            //不需要下载最新的bunlde
            NSDictionary *resultDic =[[NSDictionary alloc]initWithObjectsAndKeys:@"不需要更新",@"message", nil];
            failure([[UpdateOperation alloc]initWithDic:resultDic]);
        }
    }];
}
//执行升级
- (void)updateWithFile:(NSString *)file updateType:(ReactNativeUpdateType)updateType Success:(void (^)(UpdateOperation *opreation))success failure:(void (^)(UpdateOperation *opreation))failure {
    
    switch (updateType) {
        case ReactNativeUpdateEntiretyUpdate:
        {
            //全量 直接替换bunlde 将解压出的Temp 文件夹内的文件移到 jsbundle 下。
            NSURL *url = [[NSURL alloc]initWithString:[NSString stringWithFormat:@"file://%@",file]];
            NSData *data = [[NSData alloc]initWithContentsOfURL:url];
            NSFileManager *fileManger = [NSFileManager defaultManager];
            NSString *filePath = [[self codeDirectory]stringByAppendingPathComponent:@"main.jsbundle"];
            BOOL res =  [fileManger createFileAtPath:filePath contents:data attributes:nil];
            if(res){
                //成功
#warning 新bundle写入完成以后才会写入最新的配置文件 配置文件是对Bundle的描述
                //最后还要备份。将上一个bundle 放进去history 文件夹
            }
            //失败
        }
            break;
        case ReactNativeUpdatePartUpdate:
        {
            //增量 合成bundle   替换bundle
            NSString *fileString = [self decryptionFile:file];
            NSString *bundleString = [self decryptionFile:[[self codeDirectory] stringByAppendingPathComponent:@"main.jsbundle"]];
            NSString *string = [self addDiffSting:fileString toJSBundle:bundleString];
            //写进location
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            NSString *filePath = [[self codeDirectory]stringByAppendingPathComponent:@"main.jsbundle"];
            NSFileManager *fileManger = [NSFileManager defaultManager];
            BOOL res =  [fileManger createFileAtPath:filePath contents:data attributes:nil];
            if(res){
                //成功
            }
            //失败
            
        }
            break;
        case ReactNativeUpdatePatchUpdate:
        {
            //增量 合成bundle   替换bundle
            NSString *fileString = [self decryptionFile:file];
            NSString *bundleString = [self decryptionFile:[[self codeDirectory] stringByAppendingPathComponent:@"main.jsbundle"]];
            NSString *string = [self addDiffSting:fileString toJSBundle:bundleString];
            //写进location
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            NSString *filePath = [[self codeDirectory]stringByAppendingPathComponent:@"main.jsbundle"];
            NSFileManager *fileManger = [NSFileManager defaultManager];
            BOOL res =  [fileManger createFileAtPath:filePath contents:data attributes:nil];
            if(res){
                //成功
            }
            //失败

            
            
        }
            break;
            
        default:
            break;
    }
    
}

//下载文件
- (void)downloadLastFileFromUrl:(NSURL *)downloadUrl fileType:(NSString *)fileType completionHandler:(void (^)(NSURL * __nullable location, NSURLResponse * __nullable response, NSError * __nullable error))completionHandler {
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 60.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    NSURLSession *session =[NSURLSession sessionWithConfiguration:sessionConfig];
    session.sessionDescription = fileType;
    NSURLSessionDownloadTask *dataTask = [session downloadTaskWithURL:downloadUrl completionHandler:completionHandler];
    [dataTask resume];
}

//1.校验MD5.
//2.解压缩
//3.解密
//4.通过增量合成Bundle||全量更新，直接Bundle
//5.

//生成MD5
-(NSString *)generateMD5SignFromFile:(NSString *)file{
    NSURL *fileUrl = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",file]];
    NSData *data = [NSData dataWithContentsOfURL:fileUrl];
    NSString *fileString  = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    CocoaSecurityResult *md5 = [CocoaSecurity md5:[NSString stringWithFormat:@"%@%@",fileString,MD5Salt]];
    return md5.hex;
}

//验证MD5签名
-(BOOL)checkMD5SignValidWithConfig:(UpdaterConfig *)config fileMD5:(NSString *)md5 {
    //传古来的MD5为生成的MD5.与配置文件中的MD5比较。
    if ([md5.lowercaseString isEqualToString:config.md5.lowercaseString]) {
        return YES;
    }
    return NO;
}

//解压缩文件
-(BOOL)unZipFileWithConfig:(UpdaterConfig *)config zipFile:(NSString *)file {
    ZipArchive *unZip = [[ZipArchive alloc]init];
    [unZip UnzipOpenFile:file Password:zipPassword];
    NSString *unzipVerifyDirectory;
    if (config.type.integerValue==ReactNativeUpdateEntiretyUpdate) {
        unzipVerifyDirectory = [[self tempDirectoty]stringByAppendingPathComponent:@"main.jsbundle"];
    }else if(config.type.integerValue ==ReactNativeUpdatePartUpdate||config.type.integerValue ==ReactNativeUpdatePatchUpdate){
        unzipVerifyDirectory = [[self tempDirectoty]stringByAppendingPathComponent:@"bundle.diff"];
    }
    BOOL unZipSuccess = [unZip UnzipFileTo:unzipVerifyDirectory overWrite:YES];
    if (unZipSuccess) {
        return YES;
    }
    return NO;
}

//解密文件(文件加密后是Base64.【然后压缩<解压缩得到的是Base64>)
-(NSString *)decryptionFile:(NSString *)file{
    
    NSURL *fileUrl = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",file]];
    NSData *fileData = [[NSData alloc]initWithContentsOfURL:fileUrl];
    NSString *fileString  = [[NSString alloc]initWithData:fileData encoding:NSUTF8StringEncoding];
    CocoaSecurityResult *aes256Decrypt = [CocoaSecurity aesDecryptWithBase64:fileString
                                                                      hexKey:securityHexKey
                                                                       hexIv:securityHexIv];
    return aes256Decrypt.utf8String;
}

//应用增量文件 所使用的Bundel 和diffString 都是解密后的String
-(NSString *)addDiffSting:(NSString *)diff toJSBundle:(NSString *)bundle{
    NSData *diffData = [diff dataUsingEncoding:NSUTF8StringEncoding ];
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:diffData];
    DiffMatchPatch *match = [[DiffMatchPatch alloc]init];
    NSArray *currentArray = [match patch_apply:array toString:bundle];
    NSString *string = currentArray[0];
    return string;
}
//回滚
-(BOOL)rollBack {
    
    //将history的bundle 放进去当前的bundle文件。
    
    return NO;
}

@end
