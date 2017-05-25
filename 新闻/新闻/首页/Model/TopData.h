//
//  TopData.h
//  新闻
//
//  Created by gyh on 15/9/27.
//  Copyright © 2015年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TopData : NSObject

/**
 *  滚动条图片
 */
@property (nonatomic , copy) NSString *imgsrc;
/**
 *  滚动条标题
 */
@property (nonatomic , copy) NSString *title;
/**
 *  链接
 */
@property (nonatomic , copy) NSString *url;


/**
 *  imgurl  详细图片
 */
@property (nonatomic , copy) NSString *imgurl;
/**
 *  详细内容
 */
@property (nonatomic , copy) NSString *note;
/**
 *  标题
 */
@property (nonatomic , copy) NSString *setname;

@property (nonatomic , copy) NSString *imgtitle;

@end
/*
 {
 imgsrc = "http://cms-bucket.nosdn.127.net/1b03d292845d4c92856355dcaec1a8df20170525104206.jpeg";
 skipID = "00AO0001|2257193";
 skipType = photoset;
 subtitle = "";
 tag = photoset;
 title = "\U7279\U6717\U666e\U643a\U59bb\U5973\U4f1a\U89c1\U7f57\U9a6c\U5929\U4e3b\U6559\U6559\U7687";
 url = "00AO0001|2257193";
 }
 */
