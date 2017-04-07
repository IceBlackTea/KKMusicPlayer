//
//  KKMediaPlayer.h
//
//  Created by finger on 16/4/3.
//  Copyright © 2016年 finger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^processCallback)(float process);//播放进度
typedef void(^beginPlayCallback)(void);//开始播放
typedef void(^beginPauseCallback)(void);//暂停
typedef void(^playFinishCallback)(void);//播放完成
typedef void(^playErrorCallback)(void);//播放错误
typedef void(^loadMediaStatusCallback)(AVPlayerStatus status);//流媒体加载状态
typedef void(^bufferPercentCallback)(float bufferPercent);//流媒体缓冲百分比

@interface KKAVPlayer : NSObject
{
    
}

@property (nonatomic,assign)float totalBuffer;//中缓冲的长度
@property (nonatomic,assign)float currentPlayTime;//当前播放的时间
@property (nonatomic,assign)float totalTime;//总时长
@property (nonatomic,assign)float seekToPosition;//0~1
@property (nonatomic,assign)float curtPosition;

@property (nonatomic) NSURL *mediaUrl;

@property (nonatomic,copy) processCallback processHandler;
@property (nonatomic,copy) playFinishCallback playFinishHandler;
@property (nonatomic,copy) playErrorCallback playErrorHandler;
@property (nonatomic,copy) loadMediaStatusCallback loadMediaStatusHandler;
@property (nonatomic,copy) bufferPercentCallback bufferPercentHandler;
@property (nonatomic,copy) beginPlayCallback beginPlayHandler;
@property (nonatomic,copy) beginPauseCallback beginPauseHandler;

+ (instancetype)sharedInstance;

- (void)initPlayInfoWithUrl:(NSURL*)url
                    process:(void(^)(float process))processHandler
                  compelete:(void(^)(void))compeleteHandler
                 loadStatus:(void(^)(AVPlayerStatus status))loadStatusHandler
              bufferPercent:(void(^)(float percent))bufferPercentHandler
                      error:(void(^)(void))errorHandler;

- (void)play;
- (bool)isPlay;
- (void)pause;
- (bool)isPause;
- (void)startPlayer;
- (bool)isFirstTimeToPlay;

@end
