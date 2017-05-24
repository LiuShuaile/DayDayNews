//
//  NSString+Extension.h
//
//  Created by apple on 14-4-2.
//  Copyright (c) 2014年 gyh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Extension)
/**
 *  返回字符串所占用的尺寸
 *
 *  @param font    字体
 *  @param maxSize 最大尺寸
 */
- (CGRect)sizeWithFont:(UIFont *)font maxSize:(CGSize)maxSize;

- (NSString *)stringToMD5;
+ (NSString *)calculateTimeWithTimeFormatter:(long long)timeSecond;

//视频缓存相关
@property (readonly) NSString *md5FileName;

+ (NSString *)md5:(NSString *)str;
@end
