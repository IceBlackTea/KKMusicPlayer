//
//  KKMediaPlayer.m
//
//  Created by finger on 16/4/3.
//  Copyright © 2016年 finger. All rights reserved.
//

#import "KKAVPlayer.h"

@interface KKAVPlayer()
{
    id playTimeObserverObject;
    
    bool hasPlaymusicBefore ;
}

@property (nonatomic,strong) AVPlayer *player;//播放器对象
@property (nonatomic,strong) AVPlayerItem *curtPlayerItem;

@end

@implementation KKAVPlayer

@synthesize mediaUrl = _mediaUrl ;
@synthesize processHandler = _processHandler ;
@synthesize playErrorHandler = _playErrorHandler ;
@synthesize bufferPercentHandler = _bufferPercentHandler;
@synthesize playFinishHandler = _playFinishHandler ;
@synthesize loadMediaStatusHandler = _loadMediaStatusHandler;

+ (instancetype)sharedInstance
{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init] ;
    
    if(self){
        
        hasPlaymusicBefore = false ;
        
    }
    
    return self ;
}

- (void)dealloc
{
    if(self.player){
        self.player = nil ;
    }
    
    [self clearData];
    [self removeNotification];
}

- (void)clearData
{
    if(_mediaUrl){
        _mediaUrl = nil ;
    }
    
    if(_processHandler){
        _processHandler = nil ;
    }
    
    if(_playFinishHandler){
        _playFinishHandler = nil ;
    }
    
    if(_playErrorHandler){
        _playErrorHandler = nil ;
    }
    
    if(_loadMediaStatusHandler){
        _loadMediaStatusHandler = nil ;
    }
    
    if(_bufferPercentHandler){
        _bufferPercentHandler = nil ;
    }
}

- (void)initPlayInfoWithUrl:(NSURL*)url
                    process:(void(^)(float process))processHandler
                  compelete:(void(^)(void))compeleteHandler
                 loadStatus:(void(^)(AVPlayerStatus status))loadStatusHandler
              bufferPercent:(void(^)(float percent))bufferPercentHandler
                      error:(void(^)(void))errorHandler
{
    [self clearData];
    
    _mediaUrl = [url copy];
    
    _processHandler = [processHandler copy];
    _playFinishHandler = [compeleteHandler copy];
    _playErrorHandler = [errorHandler copy];
    _loadMediaStatusHandler = [loadStatusHandler copy];
    _bufferPercentHandler = [bufferPercentHandler copy];
}

#pragma mark -- 添加播放完成、错误通知

-(void)addNotification
{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    //给AVPlayerItem添加播放错误通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFail:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:self.player.currentItem];
}

-(void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification
{
    if(_playFinishHandler){
        _playFinishHandler();
    }
}

/**
 *  播放错误通知
 *
 *  @param notification 通知对象
 */
- (void)playbackFail:(NSNotification *)notification
{
    [self removeNotification];
    [self removeObserverFromPlayerItem:self.curtPlayerItem];
    [self removeProgressObserver];
    
    if(_playErrorHandler){
        _playErrorHandler();
    }
}

#pragma mark -- 播放进度监控
/**
 *  给播放器添加进度更新
 */
-(void)addProgressObserver
{
    __weak typeof(self) weakself = self ;
    
    //这里设置每秒执行一次
    AVPlayerItem *playerItem = self.curtPlayerItem;
    
    playTimeObserverObject = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        _currentPlayTime = CMTimeGetSeconds(time);
        _totalTime = CMTimeGetSeconds([playerItem duration]);
        _curtPosition = _currentPlayTime/_totalTime ;
        
        if(weakself.processHandler){
            weakself.processHandler(_currentPlayTime/_totalTime);
        }
        
    }];
}

- (void)removeProgressObserver
{
    if(playTimeObserverObject){
        [self.player removeTimeObserver:playTimeObserverObject];
    }
}

#pragma mark -- 播放对象的状态

/**
 *  给AVPlayerItem添加监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem
{
    if(playerItem){
        //监控状态属性，通过监控它的status也可以获得播放状态
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //监控网络加载情况属性
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem
{
    if(playerItem){
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        playerItem = nil ;
    }
}

#pragma mark -- KVO

/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([object isKindOfClass:[AVPlayerItem class]]){
        
        AVPlayerItem *playerItem = object;
        
        if ([keyPath isEqualToString:@"status"]) {
            
            AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
            
            switch (status)
            {
                case AVPlayerStatusUnknown:
                {
                    NSLog(@"加载状态：未知状态，此时不能播放");
                    
                    break;
                }
                case AVPlayerStatusReadyToPlay:
                {
                    _currentPlayTime = 0 ;
                    _totalTime = CMTimeGetSeconds([playerItem duration]);
                    
                    NSLog(@"加载状态：准备完毕，可以播放,总时长:%.2f",_totalTime);
                    
                    break;
                }
                case AVPlayerStatusFailed:
                {
                    NSLog(@"加载状态：加载失败，网络或者服务器出现问题");
                    
                    break;
                }
                default:break;
            }
            
            if(_loadMediaStatusHandler){
                _loadMediaStatusHandler(status);
            }
            
        }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
            
            NSArray *array = playerItem.loadedTimeRanges;
            CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
            
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            
            _totalBuffer = startSeconds + durationSeconds;//缓冲总长度
            if(_bufferPercentHandler){
                _bufferPercentHandler(_totalBuffer/_totalTime);
            }
            
        }
        
    }
}

#pragma mark -- 播放控制

- (void)play
{
    if(self.player.rate == 1.0){
        return ;
    }
    
    [self.player play];
}

- (bool)isPlay
{
    return self.player.rate == 1.0 ;
}

- (void)pause
{
    if(self.player.rate == 0.0){
        return ;
    }
    
    [self.player pause];
}

- (bool)isPause
{
    return self.player.rate == 0.0 ;
}

- (void)startPlayer
{
    hasPlaymusicBefore = true ;
    
    AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:_mediaUrl];
    
    if(!self.player){
        
        self.curtPlayerItem = playItem ;
        self.player = [AVPlayer playerWithPlayerItem:playItem];
        
    }else{
        
        [self removeNotification];
        [self removeObserverFromPlayerItem:self.curtPlayerItem];
        [self removeProgressObserver];
        
        self.curtPlayerItem = playItem ;
        self.player = [AVPlayer playerWithPlayerItem:playItem];
        
    }
    
    [self addProgressObserver];
    [self addObserverToPlayerItem:self.curtPlayerItem];
    [self addNotification];
    
    [self.player play];
}

- (bool)isFirstTimeToPlay
{
    return !hasPlaymusicBefore ;
}

#pragma mark -- property

- (void)setMediaUrl:(NSURL *)mediaUrl
{
    if(mediaUrl != nil){
        _mediaUrl = [mediaUrl copy];
    }
}

- (NSURL*)mediaUrl
{
    return _mediaUrl;
}

- (void)setProcessHandler:(processCallback)processHandler
{
    if(processHandler != nil){
        _processHandler = [processHandler copy];
    }
}

- (processCallback)processHandler
{
    return _processHandler ;
}

- (void)setPlayErrorHandler:(playErrorCallback)playErrorHandler
{
    if(playErrorHandler != nil){
        _playErrorHandler = [playErrorHandler copy];
    }
}

- (playErrorCallback)playErrorHandler
{
    return _playErrorHandler;
}

- (void)setPlayFinishHandler:(playFinishCallback)playFinishHandler
{
    if(playFinishHandler != nil){
        _playFinishHandler = [playFinishHandler copy];
    }
}

- (playFinishCallback)playFinishHandler
{
    return _playFinishHandler ;
}

- (void)setBufferPercentHandler:(bufferPercentCallback)bufferPercentHandler
{
    if(bufferPercentHandler != nil){
        _bufferPercentHandler = [bufferPercentHandler copy];
    }
}

- (bufferPercentCallback)bufferPercentHandler
{
    return _bufferPercentHandler ;
}

- (void)setLoadMediaStatusHandler:(loadMediaStatusCallback)loadMediaStatusHandler
{
    if(loadMediaStatusHandler != nil){
        _loadMediaStatusHandler = [loadMediaStatusHandler copy];
    }
}

- (loadMediaStatusCallback)loadMediaStatusHandler
{
    return _loadMediaStatusHandler ;
}

- (void)setSeekToPosition:(float)seekToPosition
{
    _seekToPosition = seekToPosition * _totalTime ;
    
    if(_seekToPosition < 0){
        _seekToPosition = 0 ;
    }
    if(_seekToPosition > _totalTime){
        _seekToPosition = _totalTime ;
    }
    CMTime time = CMTimeMake(_seekToPosition, 1);
    
    [self pause];
    
    [self.player seekToTime:time completionHandler:^(BOOL finish){
        if(finish){
            [self play];
        }
    }];
}

@end
