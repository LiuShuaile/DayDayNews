//
//  AVCacheManager.h
//  新闻
//
//  Created by SL on 19/05/2017.
//  Copyright © 2017 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVCacheManager : NSObject

+ (instancetype)sharedInstance;

+ (NSString *)getMd5Name:(NSString *)fileName;

- (NSString *)getPathByFileName:(NSString *)fileName;

@property (nonatomic, copy) NSString *tempPath;

@property (nonatomic, copy) NSString *diskCachePath;

- (NSString *)isExistLocalFile:(NSString *)file;

- (NSUInteger)getSize;

- (void)clearDisk;

- (void)deleteOldFilesWithCompletionBlock:(void(^)())completionBlock;
@end

/*
Xcode8出现AQDefaultDevice (173): skipping input stream 0 0 0x0
 1.选择 Product -->Scheme-->Edit Scheme
 2.选择 Arguments
 3.在Environment Variables添加一个环境变量 OS_ACTIVITY_MODE 设置值为"disable"

 
 http://flv2.bn.netease.com/videolib3/1705/20/KcLSx8643/SD/KcLSx8643-mobile.mp4 (12:13)
 
 http://flv2.bn.netease.com/tvmrepo/2017/4/F/M/ECHGRGSFM/SD/ECHGRGSFM-mobile.mp4 (13:05)
 
 http://flv2.bn.netease.com/videolib3/1705/21/UuVLF4419/SD/UuVLF4419-mobile.mp4 (12:29)
 
 */
