//
//  KKMediaFilesManager.h
//
//  Created by finger on 15/7/15.
//  Copyright (c) 2015年 finger. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "KKMusicEntity.h"

@interface KKMusicFilesManager : NSObject
{
    
}

+ (KKMusicFilesManager *)defaultMusicFilesManager;

#pragma mark -- 音乐加载，第一次运行程序时，将加载的音乐信息存储到数据库，下次读取音乐时直接从数据库读取

- (void)shouldUpdateMusic:(void(^)(bool rst))handler;

- (void)readMeidaFiles:(void(^)())handler progress:(void(^)(NSInteger curtCount,NSInteger totalCount))progress;

- (void)readAllMusicFiles;

#pragma mark -- 全部的歌曲数量，包含itnues和沙盒中的音乐

- (NSInteger)numberOfItems;

#pragma mark -- 沙盒中的音乐数量

- (NSInteger)numberOfLocalItems;

#pragma mark -- 音乐对象的获取

- (NSArray*)getMusicArray;

- (KKMusicEntity *)getItemAtIndex:(NSInteger)index;

- (KKMusicEntity *)getItemWithMediaName:(NSString *)mediaName;

#pragma mark -- 根据音乐的路径获取音乐在音乐库中的索引

- (NSInteger)getMusicIndexWithLocalPath:(NSString*)localPath;

@end
