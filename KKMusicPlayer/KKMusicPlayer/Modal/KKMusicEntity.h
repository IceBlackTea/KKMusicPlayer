//
//  KKMusicEntity.h
//
//  Created by finger on 16/6/9.
//  Copyright © 2016年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+Scale.h"

@interface KKMusicEntity : NSObject
{
    
}
@property(nonatomic,copy)UIImage *itemArtWork;//音乐封面
@property(nonatomic,assign)bool itunesMusicFlag;//是否是本地音乐
@property(nonatomic,copy)NSString *localPath;//本地音乐文件
@property(nonatomic,copy)NSString *title;//音乐名称
@property(nonatomic,copy)NSString *artist;//歌手
@property(nonatomic,copy)NSString *album;//专辑
@property(nonatomic,copy)NSURL *fileURL;
@property(nonatomic,assign)NSTimeInterval seconds ;//时长
@property(nonatomic,copy)NSString *strDuration ;//时长
@property(nonatomic,assign)long long fileSize;//文件大小

- (id)initWithMediaItem:(MPMediaItem *)item;
- (id)initWithLocalFilePath:(NSString *)localFilePath;

#pragma mark -- 获取专辑图片

- (void)getImage:(void (^)(UIImage *image))handler;
- (void)getFullImage:(void (^)(UIImage *image))handler;

@end
