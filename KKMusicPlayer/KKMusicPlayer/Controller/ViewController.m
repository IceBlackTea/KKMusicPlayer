//
//  ViewController.m
//  KKMusicPlayer
//
//  Created by finger on 2017/4/7.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "ViewController.h"
#import "SyncMusicView.h"
#import "LoadingIndicatorView.h"
#import "KKAVPlayer.h"
#import "KKMusicPlayController.h"
#import "KKMusicFilesManager.h"
#import "KKMusicFilesTableViewCell.h"
#import "KKNavViewController.h"
#import "MJRefresh.h"

static NSString *reuseIdentifier = @"reuseIdentifier";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,KKMusicPlayControllerDelegate>
{
    UITableView *mediaTable;
    
    SyncMusicView *syncView ;
    LoadingIndicatorView *indicatorView;
    
    NSInteger _lastPlayingRow;
    NSString *_curtPlayMusicPath ;
    
    KKAVPlayer *audioPlayer;
    KKMusicPlayController *playController;
    
    KKPlayMode _playMode;
    bool shouldShowPlayerCtrl;
    
    NSMutableArray *playHistoryIndexs;
}

//下拉刷新
@property (nonatomic, weak) MJRefreshNormalHeader *headerRefresh;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"music";
    
    //音频播放相关设置
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    //接受耳机线控及控制台通知
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    mediaTable = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    mediaTable.delegate = self;
    mediaTable.dataSource = self;
    [mediaTable registerNib:[UINib nibWithNibName:@"KKMusicFilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:reuseIdentifier];
    [mediaTable setAlwaysBounceVertical:YES];
    [mediaTable setShowsVerticalScrollIndicator:YES];
    [mediaTable setTableFooterView:[UIView new]];
    [self.view addSubview:mediaTable];
    
    audioPlayer = [KKAVPlayer sharedInstance];
    
    playController = [[KKMusicPlayController alloc]init];
    playController.delegate = self ;
    
    _playMode = KKPlayModeRandomPlay ;
    playHistoryIndexs = [[NSMutableArray alloc]init];
    
    [self initRefreshControl];
    [self loadMusicData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshPlayInfo];
}

#pragma mark -- 页面下拉刷新

- (void)initRefreshControl
{
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadMusicData)];
    header.lastUpdatedTimeLabel.hidden = YES;
    
    header.stateLabel.hidden = YES;
    
    mediaTable.mj_header = header;
    
    self.headerRefresh = header;
}

- (void)endRefresh
{
    [mediaTable.mj_header endRefreshing];
}

#pragma mark -- 数据加载

- (void)loadMusicData
{
    [self showIndicatorView];
    
    [[KKMusicFilesManager defaultMusicFilesManager]shouldUpdateMusic:^(bool rst) {
        
        if(rst){
            
            [[KKMusicFilesManager defaultMusicFilesManager] readMeidaFiles:^() {
                
                [self refreshPlayInfo];
                
            }progress:^(NSInteger curtCount, NSInteger totalCount) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if(!syncView){
                        [self showSyncView];
                    }
                    CGFloat progress = ((CGFloat)curtCount / (CGFloat)totalCount);
                    [syncView setCircleViewPercent:progress];
                    [syncView setCircleViewMsg:[NSString stringWithFormat:@"%d%@",(int)(progress * 100),@"%"]];
                    if(progress >= 1.0){
                        [self hideSyncView];
                    }
                    
                });
                
            }];
            
        }else{
            [self refreshPlayInfo];
        }
        
    }];
}

- (void)refreshPlayInfo
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSArray *musicArray = [[KKMusicFilesManager defaultMusicFilesManager]getMusicArray];
        for(NSInteger i = 0 ; i < musicArray.count ; i ++){
            if(i == _lastPlayingRow){
                KKMusicEntity *musicEntity = [musicArray objectAtIndex:i];
                _curtPlayMusicPath = [[musicEntity fileURL]absoluteString];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshView];
            [self endRefresh];
            [self hideIndicatorView];
        });
    });
}

- (void)refreshView
{
    NSInteger tatolCount = [[KKMusicFilesManager defaultMusicFilesManager]numberOfItems] ;//全部文件，包括itunes中的音乐文件
    
    if(_lastPlayingRow >= tatolCount ||
       _lastPlayingRow < 0){
        _lastPlayingRow = 0 ;
    }
    
    if(tatolCount){
        
        KKMusicFilesTableViewCell *cellView = [mediaTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastPlayingRow inSection:0]];
        if (cellView != nil){
            if (audioPlayer.isPlay){
                cellView.isPlaying = YES;
            }else{
                cellView.isPaused = YES;
            }
        }
        
    }
    
    [mediaTable reloadData];
    [mediaTable setScrollEnabled:tatolCount];
}

#pragma mark -- UITableViewDelegate && UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 ;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[KKMusicFilesManager defaultMusicFilesManager]numberOfItems];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KKMusicFilesTableViewCell *cellView = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:indexPath.row];
    [mediaEntity getImage:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cellView.image = image;
        });
    }];
    cellView.title = [mediaEntity.title stringByDeletingPathExtension];
    cellView.artist = mediaEntity.artist;
    
    if ([_curtPlayMusicPath isEqualToString:[[mediaEntity fileURL]absoluteString]]){
        if (audioPlayer.isPlay){
            cellView.isPlaying = YES;
        }else{
            cellView.isPaused = YES;
        }
    }else{
        cellView.isPlaying = NO;
    }
    
    return cellView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KKMusicFilesTableViewCell *lastPlayingCell = (KKMusicFilesTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastPlayingRow inSection:indexPath.section]];
    
    if (lastPlayingCell != nil){
        lastPlayingCell.isPlaying = NO;
    }
    
    shouldShowPlayerCtrl = true ;
    
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:indexPath.row];
    
    if(![_curtPlayMusicPath isEqualToString:[[mediaEntity fileURL]absoluteString]]){
        
        [self initPlayBlockWithUrl:[mediaEntity fileURL]
                        musucIndex:indexPath.row
                         musicName:[mediaEntity.title stringByDeletingPathExtension]
                       musicArtist:mediaEntity.artist];
        
        [audioPlayer startPlayer];
        
    }else{
        [self showPlayerController];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -- KKMusicPlayControllerDelegate

- (void)playController_playNextMusic
{
     [self playNextMusic];
}

- (void)playController_playPreMusic
{
    [self playPreMusic];
}

- (void)playController_playPause
{
    if([audioPlayer isFirstTimeToPlay]){
        
        [self playNextMusic];
        
    }else{
        
        if([audioPlayer isPlay]){
            
            [audioPlayer pause];
            [playController setPlayerStatue:PlayerStatusPause];
            
        }else{
            
            [audioPlayer play];
            [playController setPlayerStatue:PlayerStatusPlay];
            
        }
        
        [self updateNowPlayingInfo:false];
        
    }
}

- (void)playController_changePlayMode
{
    UIImage *image = [UIImage imageNamed:@"shuffle_w"];
    UIImage *imagePlayView = [UIImage imageNamed:@"b_shuffle"];
    
    if(++_playMode > KKPlayModeRandomPlay){
        _playMode = KKPlayModeSinglePlay ;
    }
    
    switch(_playMode)
    {
        case KKPlayModeSinglePlay:
        {
            image = [UIImage imageNamed:@"repeat_song_w"];
            imagePlayView = [UIImage imageNamed:@"b_repeat_song"];
            break;
        }
        case KKPlayModeCircularPlay:
        {
            image = [UIImage imageNamed:@"repeat_all_w"];
            imagePlayView = [UIImage imageNamed:@"b_repeat_all"];
            break;
        }
        case KKPlayModeRandomPlay:
        {
            image = [UIImage imageNamed:@"shuffle_w"];
            imagePlayView = [UIImage imageNamed:@"b_shuffle"];
            break;
        }
    }
    
    playController.playMode = _playMode ;
}

- (void)playController_seekToTime:(CGFloat)pos
{
    if(audioPlayer && [audioPlayer isPlay]){
        audioPlayer.seekToPosition = pos ;
    }
}

- (void)playController_PlayMusicWithPath:(NSString *)path
{
    KKMusicFilesTableViewCell *lastPlayingCell = (KKMusicFilesTableViewCell *)[mediaTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastPlayingRow inSection:0]];
    if (lastPlayingCell != nil){
        lastPlayingCell.isPlaying = NO;
    }
    
    
    [playHistoryIndexs addObject:[NSNumber numberWithInteger:_lastPlayingRow]];
    
    NSArray *array = [[KKMusicFilesManager defaultMusicFilesManager]getMusicArray];
    
    NSInteger nextRow = 0;
    for(KKMusicEntity *entity in array){
        if([[entity.fileURL absoluteString]isEqualToString:path]){
            nextRow = [array indexOfObject:entity];
            break ;
        }
    }
    
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:nextRow];
    
    [self initPlayBlockWithUrl:[mediaEntity fileURL]
                    musucIndex:nextRow
                     musicName:[mediaEntity.title stringByDeletingPathExtension]
                   musicArtist:mediaEntity.artist];
    
    [audioPlayer startPlayer];
}

#pragma mark -- 加载进度

- (void)showIndicatorView
{
    [self hideIndicatorView];
    
    indicatorView = [[LoadingIndicatorView alloc]init];
    [indicatorView startAnimateWithTimeOut:8.0];
}

- (void)hideIndicatorView
{
    if(indicatorView){
        [indicatorView removeFromSuperview];
        indicatorView = nil ;
    }
}

- (void)showSyncView
{
    [self hideIndicatorView];
    [self hideSyncView];
    
    syncView =[[SyncMusicView alloc]init];
    [syncView setCircleViewPercent:0];
    [syncView setCircleViewMsg:[NSString stringWithFormat:@"0%@",@"%"]];
    [syncView setStrMsg:@"同步音乐中..."];
    [syncView startAnimate];
}

- (void)hideSyncView
{
    if(syncView){
        
        [syncView dismiss];
        [syncView removeFromSuperview];
        syncView = nil ;
    }
}

#pragma mark -- 音乐播放

- (void)initPlayBlockWithUrl:(NSURL*)url musucIndex:(NSInteger)index musicName:(NSString*)musicName musicArtist:(NSString*)artist
{
    [audioPlayer initPlayInfoWithUrl:url process:^(float process) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            playController.sliderValue = process ;
        });
        
    } compelete:^{
        
        [self playNextMusic];
        
    } loadStatus:^(AVPlayerStatus status) {
        
        if(status == AVPlayerStatusReadyToPlay){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                KKMusicFilesTableViewCell *cell = (KKMusicFilesTableViewCell *)[mediaTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                cell.isPlaying = YES;
                
                cell = (KKMusicFilesTableViewCell *)[mediaTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastPlayingRow inSection:0]];
                cell.isPlaying = NO;
                
                _lastPlayingRow = index;
                
                KKMusicEntity *entity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:_lastPlayingRow];
                _curtPlayMusicPath = [entity.fileURL absoluteString];
                
                [self updateNowPlayingInfo:false];
                
                [self showPlayerController];
                
                NSUInteger indexs[2] = {0, _lastPlayingRow};
                NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:indexs length:2];
                if(_lastPlayingRow < [mediaTable numberOfRowsInSection:0]){
                    [mediaTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
                }
                
            });
            
        }else{
            [self performSelector:@selector(playNextMusic) withObject:nil afterDelay:1.0];
        }
        
    } bufferPercent:^(float percent) {
        
    }error:^{
        
        _lastPlayingRow = index ;
        
        KKMusicEntity *entity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:_lastPlayingRow];
        _curtPlayMusicPath = [entity.fileURL absoluteString];
        
        [self updateNowPlayingInfo:true];
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"播放出现错误" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
        
    }];
}

#pragma mark -- 设置控制台或锁屏时歌曲的显示信息

- (void)updateNowPlayingInfo:(BOOL)isClear
{
    MPNowPlayingInfoCenter *nowPlayerCenter = [MPNowPlayingInfoCenter defaultCenter];
    
    NSMutableDictionary *nowPlayingInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    if(isClear){
        
        [nowPlayerCenter setNowPlayingInfo:nil];
        
    }else{
        
        KKMusicEntity *entity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:_lastPlayingRow];
        
        if(entity){
            
            [entity getFullImage:^(UIImage *image) {
                
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = [entity.title stringByDeletingPathExtension];
                
                nowPlayingInfo[MPMediaItemPropertyArtist] = entity.artist;
                
                
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = entity.album;
                
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithDouble:entity.seconds];//总时长
                
                if (image != nil){
                    [nowPlayingInfo setObject:[[MPMediaItemArtwork alloc] initWithImage:image] forKey:MPMediaItemPropertyArtwork];
                }else{
                    //图片在mainBundle 中
                    [nowPlayingInfo setObject:[[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"default-artwork"]] forKey:MPMediaItemPropertyArtwork];
                }
                
                CGFloat currentPlayTime = [audioPlayer currentPlayTime];
                
                [nowPlayingInfo setObject:[NSNumber numberWithDouble:currentPlayTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime]; //当前音乐已经播放的时长
                
                if(audioPlayer.isPlay){
                    [nowPlayingInfo setObject:[NSNumber numberWithDouble:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                }else{
                    [nowPlayingInfo setObject:[NSNumber numberWithDouble:0.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
                }
                
                [nowPlayerCenter setNowPlayingInfo:nowPlayingInfo];
                
            }];
            
        }
        
    }
}

#pragma mark -- 显示专辑页面

- (void)showPlayerController
{
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:_lastPlayingRow];
    playController.musicName = [mediaEntity.title stringByDeletingPathExtension];
    playController.sliderValue = audioPlayer.curtPosition ;
    playController.artistName = mediaEntity.artist ;
    playController.playMode = _playMode ;
    playController.totalTime = audioPlayer.totalTime ;
    playController.curtPlayPath = _curtPlayMusicPath;
    
    [mediaEntity getFullImage:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            playController.artistImage = image ;
        });
    }];
    
    if(audioPlayer.isPlay){
        playController.playerStatue = PlayerStatusPlay ;
    }else{
        playController.playerStatue = PlayerStatusPause ;
    }
    
    if(!playController.currentShow && shouldShowPlayerCtrl){
        playController.currentShow = true ;
        KKNavViewController *nav = [[KKNavViewController alloc]initWithRootViewController:playController];
        [nav setNavigationBarHidden:YES];
        [self presentViewController:nav animated:YES completion:^{}];
    }
}

#pragma mark - 音乐播放结束,播放下一曲

- (void)playPreMusic
{
    KKMusicFilesTableViewCell *lastPlayingCell = (KKMusicFilesTableViewCell *)[mediaTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastPlayingRow inSection:0]];
    if (lastPlayingCell != nil){
        lastPlayingCell.isPlaying = NO;
    }
    
    NSInteger index = -1 ;
    
    if(_playMode == KKPlayModeCircularPlay){
        
        index = _lastPlayingRow - 1 ;
        if(index < 0){
            index = [[KKMusicFilesManager defaultMusicFilesManager] numberOfItems] - 1 ;
        }
        
    }else if(_playMode == KKPlayModeRandomPlay){
        
        if([playHistoryIndexs count]){
            index = [[playHistoryIndexs lastObject]integerValue];
            [playHistoryIndexs removeLastObject];
        }else{
            index = [self createNextIndexWidthPlayMode:_playMode currentIndex:_lastPlayingRow];
        }
        
    }else if (_playMode == KKPlayModeSinglePlay){
        index = _lastPlayingRow ;
    }
    
    if (index > [[KKMusicFilesManager defaultMusicFilesManager] numberOfItems] - 1 || index < 0){
        index = 0 ;
    }
    
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:index];
    
        
    [self initPlayBlockWithUrl:[mediaEntity fileURL]
                    musucIndex:index
                     musicName:[mediaEntity.title stringByDeletingPathExtension]
                   musicArtist:mediaEntity.artist];
    
    [audioPlayer startPlayer];
}

- (void)playNextMusic
{
    KKMusicFilesTableViewCell *lastPlayingCell = (KKMusicFilesTableViewCell *)[mediaTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_lastPlayingRow inSection:0]];
    if (lastPlayingCell != nil){
        lastPlayingCell.isPlaying = NO;
    }
    
    
    [playHistoryIndexs addObject:[NSNumber numberWithInteger:_lastPlayingRow]];
    
    NSInteger nextRow = [self createNextIndexWidthPlayMode:_playMode currentIndex:_lastPlayingRow];
    if (nextRow > [[KKMusicFilesManager defaultMusicFilesManager] numberOfItems] - 1){
        nextRow = 0;
    }
    
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:nextRow];

    [self initPlayBlockWithUrl:[mediaEntity fileURL]
                    musucIndex:nextRow
                     musicName:[mediaEntity.title stringByDeletingPathExtension]
                   musicArtist:mediaEntity.artist];
    
    [audioPlayer startPlayer];
}

#pragma mark -- 生成下一曲索引

- (NSInteger)createNextIndexWidthPlayMode:(NSInteger)playMode currentIndex:(NSInteger)currentIndex
{
    NSInteger newIndex = 0 ;
    NSInteger numberOfItems = [[KKMusicFilesManager defaultMusicFilesManager] numberOfItems] ;
    
    switch (playMode)
    {
        case KKPlayModeSinglePlay:
        {
            newIndex = currentIndex;
            
            break ;
        }
        case KKPlayModeCircularPlay:
        {
            newIndex = ++currentIndex ;
            if (newIndex > numberOfItems - 1){
                newIndex = 0;
            }
            
            break ;
        }
        case KKPlayModeRandomPlay:
        {
            if(numberOfItems <= 1){
                return 0 ;
            }
            while (true) {
                newIndex = (int)((arc4random() % (numberOfItems)));
                if(newIndex != currentIndex){
                    break ;
                }
            }
            
            break ;
        }
            
        default:break;
    }
    
    return newIndex ;
}

@end
