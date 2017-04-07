//
//  KKMusicPlayController.m
//  Apowersoft IOS AirMore
//
//  Created by wangxutech on 16/5/4.
//  Copyright © 2016年 Joni. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "KKCircularProgressView.h"
#import "KKMusicPlayController.h"
#import "UIImageView+BlurredImage.h"
#import "KKMusicFilesManager.h"
#import "KKMusicListController.h"

@interface KKMusicPlayController ()<KKMusicListControllerDelegate>
{
    __weak IBOutlet UIImageView *_musicImageView;
    
    __weak IBOutlet UIView *_topView;
    __weak IBOutlet UILabel *_artistNameLabel;
    __weak IBOutlet UILabel *_musicNameLabel;
    __weak IBOutlet UIScrollView *_musicNameScrollView;
    
    __weak IBOutlet UIButton *_backButton;
    
    __weak IBOutlet UIView *_buttomVuew;
    __weak IBOutlet UILabel *_startTimerLabel;
    __weak IBOutlet UILabel *_endTimeLabel;
    __weak IBOutlet UISlider *_sliderView;
    __weak IBOutlet UIButton *_playNextButton;
    __weak IBOutlet UIButton *_playPauseButton;
    __weak IBOutlet UIButton *_prePlayButton;
    __weak IBOutlet UIButton *_playModeButton;
    __weak IBOutlet UIButton *playListButton;
    
    bool bSliderDraging;
    bool bForwardStep ;
    float preSliderValue;
    bool bHasShow;
    bool bSHouldAdjustSliderPos ;//由于播放器快进快退时有延时，需要调整滑动条的位置，只有在拉动滑块的需要调整
    
    KKCircularProgressView *_circularProgressView;
    
    NSTimer *timer ;
    CGFloat _angle ;
    
    //歌曲名称滚动
    NSTimer *musicNameScrollTimer ;
    float offsetX ;
    bool bMoveToLeft ;
    
    UIVisualEffectView *bkBlurEffectView;
    UIImageView *bkImageView;
}

@property(nonatomic,weak)KKMusicListController *listCtrl ;

@end

@implementation KKMusicPlayController

- (instancetype)init
{
    self = [super init];
    
    if(self){
        
    }
    
    return self ;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setFrame:[[UIScreen mainScreen]bounds]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _musicImageView.image = _artistImage ;
    _musicImageView.contentMode = UIViewContentModeScaleAspectFill ;
    _musicImageView.layer.cornerRadius = _musicImageView.frame.size.width / 2 ;
    _musicImageView.layer.masksToBounds = YES ;
    _musicImageView.userInteractionEnabled = YES ;
    
    bkImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    bkImageView.contentMode = UIViewContentModeScaleAspectFill;
    bkImageView.userInteractionEnabled = YES;
    [self.view insertSubview:bkImageView atIndex:0];
    
    UIBlurEffect *bkBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    bkBlurEffectView = [[UIVisualEffectView alloc] initWithEffect:bkBlurEffect];
    bkBlurEffectView.frame = [[UIScreen mainScreen]bounds];
    bkBlurEffectView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    [bkImageView insertSubview:bkBlurEffectView atIndex:0];
    
    _circularProgressView = [[KKCircularProgressView alloc] initWithFrame:CGRectMake(_musicImageView.frame.origin.x - 4 , _musicImageView.frame.origin.y - 7, CGRectGetWidth(_musicImageView.frame) + 12, CGRectGetHeight(_musicImageView.frame) + 12)
                                                                backColor:[[UIColor whiteColor]colorWithAlphaComponent:0.4]
                                                            progressColor:[UIColor colorWithRed:255.0/255.0 green:131.0/255.0 blue:0/255.0 alpha:1.0]
                                                                lineWidth:1.5];
    [self.view insertSubview:_circularProgressView belowSubview:_musicImageView];
    [self.view insertSubview:_circularProgressView belowSubview:_musicImageView];
    
    _sliderView.minimumTrackTintColor = [UIColor whiteColor];
    _sliderView.maximumTrackTintColor = [[UIColor whiteColor]colorWithAlphaComponent:0.4];
    [_sliderView setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    
    _musicNameLabel.text = _musicName ;
    _musicNameLabel.textColor = [UIColor whiteColor];
    _musicNameLabel.font = [UIFont systemFontOfSize:20.0 weight:0.5];
    
    _artistNameLabel.text = _artistName;
    _artistNameLabel.textColor = [UIColor whiteColor];
    
    _startTimerLabel.textColor = [UIColor whiteColor];
    _endTimeLabel.textColor = [UIColor whiteColor];
    
    bHasShow = false ;
    bForwardStep = true ;//进度条向前走
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [self rotateToInterfaceOrientation:[[UIApplication sharedApplication]statusBarOrientation]];
    
    bHasShow = true ;
    
    bSHouldAdjustSliderPos = false ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleDefault];
    
    if(timer && [timer isValid]){
        [timer invalidate];
        timer = nil ;
    }
    _angle = 0 ;
    
    if(musicNameScrollTimer && [musicNameScrollTimer isValid]){
        [musicNameScrollTimer invalidate];
        musicNameScrollTimer = nil ;
    }
}

#pragma mark -- action

- (IBAction)prePlayButtonClick:(id)sender
{
    if(_delegate && [_delegate respondsToSelector:@selector(playController_playPreMusic)]){
        [_delegate playController_playPreMusic];
    }
}

- (IBAction)playNextButtonClick:(id)sender
{
    if(_delegate && [_delegate respondsToSelector:@selector(playController_playNextMusic)]){
        [_delegate playController_playNextMusic];
    }
}

- (IBAction)playPauseButtonClick:(id)sender
{
    if(_delegate && [_delegate respondsToSelector:@selector(playController_playPause)]){
        [_delegate playController_playPause];
    }
}

- (IBAction)backButtonClick:(id)sender
{
    _currentShow = false ;
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (IBAction)sliderBeginDrag:(id)sender
{
    bSliderDraging = true ;
    preSliderValue = _sliderValue ;
}

- (IBAction)sliderValueChange:(id)sender
{
    UISlider *slider = (UISlider*)sender ;
    
    _sliderValue = slider.value ;
    
    CGFloat curtTime = _sliderValue * _totalTime;
    
    _startTimerLabel.text = [self timeToString:curtTime] ;
    _endTimeLabel.text = [self timeToString:_totalTime - curtTime] ;
}

- (IBAction)sliderDragEnd:(id)sender
{
    CGFloat pos = _sliderView.value ;
    
    if(_delegate && [_delegate respondsToSelector:@selector(playController_seekToTime:)]){
        
        [_delegate playController_seekToTime:pos];
        
        bSliderDraging = false ;
        
        bSHouldAdjustSliderPos = true ;
        
        if(pos > preSliderValue){
            bForwardStep = true ;
        }else{
            bForwardStep = false ;
        }
        
    }
}

- (IBAction)playListButtonClicked:(id)sender
{
    [self showMusicList];
}

- (IBAction)changePlayMode:(id)sender
{
    if(_delegate && [_delegate respondsToSelector:@selector(playController_changePlayMode)]){
        [_delegate playController_changePlayMode];
    }
}

#pragma mark -- @property

- (void)setMusicName:(NSString *)musicName
{
    _musicName = musicName ;
    
    _musicNameLabel.lineBreakMode = NSLineBreakByWordWrapping ;
    _musicNameLabel.text = musicName ;
    
    if(bHasShow){
        
        if(musicNameScrollTimer && [musicNameScrollTimer isValid]){
            [musicNameScrollTimer invalidate];
            musicNameScrollTimer = nil ;
        }
        
        CGSize size = [self sizeForString:musicName font:_musicNameLabel.font];
        CGRect frame = _musicNameLabel.frame ;
        frame.size.width = size.width;
        if(frame.size.width < _musicNameScrollView.frame.size.width){
            frame.size.width = _musicNameScrollView.frame.size.width ;
        }
        frame.origin.x = 0 ;
        _musicNameLabel.frame = frame ;
        _musicNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _musicNameLabel.textAlignment = NSTextAlignmentCenter;
        
        if(size.width > _musicNameScrollView.frame.size.width){
            bMoveToLeft = true ;
            _musicNameLabel.textAlignment = NSTextAlignmentLeft;
            musicNameScrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/36.0 target:self selector:@selector(animateLabel) userInfo:nil repeats:YES];
            offsetX = fabs(_musicNameLabel.frame.origin.x - (_musicNameLabel.frame.size.width - _musicNameScrollView.frame.size.width) - 10 );
        }
    }
}

- (void)animateLabel
{
    float perStep = 0.3 ;
    
    if(bMoveToLeft){
        
        CGRect frame = _musicNameLabel.frame ;
        frame.origin.x -= perStep ;
        _musicNameLabel.frame = frame ;
        
        if(frame.origin.x <= -offsetX){
            frame.origin.x = -offsetX ;
            _musicNameLabel.frame = frame ;
            bMoveToLeft = false ;
        }
        
    }else{
        
        CGRect frame = _musicNameLabel.frame ;
        frame.origin.x += perStep ;
        _musicNameLabel.frame = frame ;
        
        if(frame.origin.x >= 0){
            frame.origin.x = 0 ;
            _musicNameLabel.frame = frame ;
            bMoveToLeft = true ;
        }
    }
}

- (void)setArtistName:(NSString *)artistName
{
    _artistName = artistName ;
    _artistNameLabel.text = artistName ;
}

- (void)setSliderValue:(float)sliderValue
{
    if(bSliderDraging){
        return ;
    }
    
    if(bSHouldAdjustSliderPos){
        
        if(bForwardStep){
            if(sliderValue < _sliderValue){
                return ;
            }
        }else{
            if(sliderValue > _sliderValue){
                return ;
            }
        }
        
    }
    
    bForwardStep = true ;
    bSHouldAdjustSliderPos = false ;
    
    _sliderValue = sliderValue ;
    _sliderView.value = sliderValue ;
    _circularProgressView.progress = sliderValue ;
    
    long long curtTime = _sliderValue * _totalTime;
    _startTimerLabel.text = [self timeToString:curtTime] ;
    _endTimeLabel.text = [self timeToString:_totalTime - curtTime] ;
}

- (void)setPlayerStatue:(KKAudioPlayerStatus)playerStatue
{
    _playerStatue = playerStatue ;
    if(_playerStatue == PlayerStatusPause){
        [_playPauseButton setImage:[UIImage imageNamed:@"play-ctrl"] forState:UIControlStateNormal];
        [self stopRatationImage];
    }else{
        [_playPauseButton setImage:[UIImage imageNamed:@"pause-ctrl"] forState:UIControlStateNormal];
        [self startRatationImage];
    }
}

- (void)setArtistImage:(UIImage *)artistImage
{
    [self stopRatationImage];
    
    _angle = 0 ;
    _musicImageView.transform = CGAffineTransformIdentity ;
    
    if(artistImage == nil){
        _artistImage = [UIImage imageNamed:@"default-artwork"] ;
    }else{
        _artistImage = artistImage;
    }
    
    [_musicImageView setImage:_artistImage] ;
    [bkImageView setImage:_artistImage];
    
    [self startRatationImage];
}

- (void)setPlayMode:(NSInteger)playMode
{
    _playMode = playMode ;
    
    [self setPlayModeImage];
}

- (void)setCurtPlayPath:(NSString *)curtPlayPath
{
    _curtPlayPath = curtPlayPath ;
    
    self.listCtrl.curtPlayPath = curtPlayPath ;
}

#pragma mark -- 旋转视图

- (void)startRatationImage
{
    if(timer && [timer isValid]){
        [timer invalidate];
        timer = nil ;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/36.0 target:self selector:@selector(ratationImage) userInfo:nil repeats:YES];
}

- (void)stopRatationImage
{
    if(timer && [timer isValid]){
        [timer invalidate];
        timer = nil ;
    }
}

- (void)ratationImage
{
    _angle += ( 1.0 / (360.0 * 4.0) );
    _musicImageView.layer.anchorPoint = CGPointMake(0.5,0.5);
    _musicImageView.transform = CGAffineTransformMakeRotation(_angle * M_PI);
}

#pragma mark -- 设置播放模式图标

- (void)setPlayModeImage
{
    UIImage *image = [UIImage imageNamed:@"shuffle_w"];
    
    switch(_playMode)
    {
        case KKPlayModeSinglePlay:
        {
            image = [UIImage imageNamed:@"repeat_song_w"];
            
            break;
        }
        case KKPlayModeCircularPlay:
        {
            image = [UIImage imageNamed:@"repeat_all_w"];
            
            break;
        }
        case KKPlayModeRandomPlay:
        {
            image = [UIImage imageNamed:@"shuffle_w"];
            
            break;
        }
    }
    [_playModeButton setImage:image forState:UIControlStateNormal];
}

#pragma mark -- 屏幕旋转

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self rotateToInterfaceOrientation:toInterfaceOrientation];
}

- (void)rotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    CGRect mainFrame = [UIScreen mainScreen].bounds ;
    if(orientation == UIInterfaceOrientationPortrait ||
       orientation == UIInterfaceOrientationPortraitUpsideDown){
        if(mainFrame.size.width > mainFrame.size.height){
            CGFloat width = mainFrame.size.width ;
            mainFrame.size.width = mainFrame.size.height ;
            mainFrame.size.height = width ;
        }
    }else{
        if(mainFrame.size.width < mainFrame.size.height){
            CGFloat width = mainFrame.size.width ;
            mainFrame.size.width = mainFrame.size.height ;
            mainFrame.size.height = width ;
        }
    }
    
    self.view.frame = mainFrame ;
    
    [bkBlurEffectView setFrame:[[UIScreen mainScreen]bounds]];
    [bkImageView setFrame:self.view.bounds];
    if(!_artistImage){
        _artistImage = [UIImage imageNamed:@"default-artwork"];
    }
    [bkImageView setImage:_artistImage];
    
    NSInteger width = self.view.frame.size.width ;
    NSInteger height = self.view.frame.size.height ;
    
    //////////////////////////top///////////////////////////////////////////////
    
    NSInteger lrIntervel = 0;
    NSInteger tbInterval = 30;
    NSInteger labelHeight = 35 ;
    NSInteger topButtonWH = 44 ;
    NSInteger labelWidth = width - 2 * topButtonWH - 20;
    _topView.frame = CGRectMake(0, 0, width, height * 0.3);
    _backButton.frame = CGRectMake(lrIntervel, tbInterval, topButtonWH, topButtonWH);
    _musicNameScrollView.frame = CGRectMake((width - labelWidth)/2,tbInterval, labelWidth, labelHeight) ;
    _musicNameLabel.frame = _musicNameScrollView.bounds;
    _artistNameLabel.frame = CGRectMake(_musicNameScrollView.frame.origin.x, _musicNameScrollView.frame.origin.y + _musicNameScrollView.frame.size.height + 5, labelWidth, labelHeight/2);
    
    [self stopRatationImage];
    
    CGRect frame = CGRectMake(0, 0, width * 0.7, width * 0.7);
    if(frame.size.width > 400){
        frame.size.width = 400;
        frame.size.height = 400;
    }
    frame.origin.x = (width - frame.size.width) / 2 ;
    frame.origin.y = (height - frame.size.height) / 2 - 20 ;
    _angle = 0 ;
    _musicImageView.transform = CGAffineTransformIdentity ;
    _musicImageView.frame = frame ;
    _musicImageView.layer.cornerRadius = _musicImageView.frame.size.width / 2 ;
    _musicImageView.image = _artistImage ;
    
    [self startRatationImage];
    
    _circularProgressView.frame = CGRectInset(_musicImageView.frame, -12, -12);
    
    //////////////////////////bottom///////////////////////////////////////////////
    
    NSInteger vInterVal = 20 ;
    NSInteger lrInterval = 13 ;
    NSInteger timeLabelWidth = 50 ;
    NSInteger buttonWH = 60 ;
    NSInteger smallBtnWH = 40 ;
    NSInteger favoriteBtnWH = 35 ;
    NSInteger playModeBtnWH = 30 ;
    NSInteger sliderWidth = width -  2 * timeLabelWidth - 2 * lrInterval ;
    NSInteger sliderHeight = 30 ;
    
    NSInteger buttonStartX = 0 ;
    NSInteger buttonViewWidth = width ;
    if(buttonViewWidth > 400){
        buttonViewWidth = 400 ;
        buttonStartX = (width - buttonViewWidth) / 2 ;
    }
    NSInteger buttonInterval = (buttonViewWidth - buttonWH - smallBtnWH * 2 - favoriteBtnWH - playModeBtnWH - 2 * lrInterval) / 4;
    
    _buttomVuew.frame = CGRectMake(0,height * 0.6, width, height * 0.4);
    
    NSInteger startY = _buttomVuew.frame.size.height - buttonWH ;
    NSInteger offsetY = 20 ;
    
    playListButton.frame = CGRectMake(lrInterval + buttonStartX, startY + (buttonWH - favoriteBtnWH ) / 2 - offsetY, favoriteBtnWH, favoriteBtnWH);
    _prePlayButton.frame = CGRectMake(playListButton.frame.origin.x + playListButton.frame.size.width + buttonInterval, startY + (buttonWH - smallBtnWH ) / 2 - offsetY, smallBtnWH, smallBtnWH);
    _playPauseButton.frame = CGRectMake(_prePlayButton.frame.origin.x + _prePlayButton.frame.size.width + buttonInterval, startY + (buttonWH - buttonWH ) / 2 - offsetY, buttonWH, buttonWH);
    _playNextButton.frame = CGRectMake(_playPauseButton.frame.origin.x + _playPauseButton.frame.size.width + buttonInterval, startY + (buttonWH - smallBtnWH ) / 2 - offsetY, smallBtnWH, smallBtnWH);
    _playModeButton.frame = CGRectMake(_playNextButton.frame.origin.x + _playNextButton.frame.size.width + buttonInterval,  startY + (buttonWH - playModeBtnWH ) / 2 - offsetY, playModeBtnWH, playModeBtnWH);
    
    _startTimerLabel.frame = CGRectMake(lrInterval, _playNextButton.frame.origin.y - vInterVal - sliderHeight , timeLabelWidth, sliderHeight);
    _sliderView.frame = CGRectMake(_startTimerLabel.frame.origin.x + _startTimerLabel.frame.size.width, _startTimerLabel.frame.origin.y, sliderWidth, sliderHeight);
    _endTimeLabel.frame = CGRectMake(_sliderView.frame.size.width + _sliderView.frame.origin.x, _startTimerLabel.frame.origin.y, timeLabelWidth, sliderHeight);
    
    CGSize size = [self sizeForString:_musicName font:_musicNameLabel.font];
    frame = _musicNameLabel.frame ;
    frame.size.width = size.width;
    if(frame.size.width < _musicNameScrollView.frame.size.width){
        frame.size.width = _musicNameScrollView.frame.size.width ;
    }
    frame.origin.x = 0 ;
    _musicNameLabel.frame = frame ;
    _musicNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _musicNameLabel.textAlignment = NSTextAlignmentCenter;
    _musicNameLabel.text = _musicName ;
    
    if(musicNameScrollTimer && [musicNameScrollTimer isValid]){
        [musicNameScrollTimer invalidate];
        musicNameScrollTimer = nil ;
    }
    if(size.width > _musicNameScrollView.frame.size.width){
        bMoveToLeft = true ;
        _musicNameLabel.textAlignment = NSTextAlignmentLeft;
        musicNameScrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/36.0 target:self selector:@selector(animateLabel) userInfo:nil repeats:YES];
        offsetX = fabs(_musicNameLabel.frame.origin.x - (_musicNameLabel.frame.size.width - _musicNameScrollView.frame.size.width) - 10 );
    }
    
    if(_playerStatue == PlayerStatusPause){
        [_playPauseButton setImage:[UIImage imageNamed:@"play-ctrl"] forState:UIControlStateNormal];
    }else{
        [_playPauseButton setImage:[UIImage imageNamed:@"pause-ctrl"] forState:UIControlStateNormal];
    }
    
    [self setPlayModeImage];
}

#pragma mark -- 时间转字符串

- (NSString *)timeToString:(long long)time
{
    if (time>0)
    {
        int hour = (int)(time / 3600);
        int minute = (int)((time % 3600) / 60);
        int second = (int)((time) % 60);
        if (hour>0)
        {
            return [NSString stringWithFormat:@"%02d:%02d:%02d",hour, minute, second];
        }
        else
        {
            return [NSString stringWithFormat:@"%02d:%02d", minute, second];
        }
    }
    else
    {
        return @"00:00";
    }
    
}

#pragma mark -- 计算字符串的Size

- (CGSize)sizeForString:(NSString*)text font:(UIFont*)font
{
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat maxWidth = screen.size.width;
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
    
    CGSize textSize = CGSizeZero;
    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        
        NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
        
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineBreakMode:NSLineBreakByCharWrapping];
        
        NSDictionary *attributes = @{ NSFontAttributeName : font, NSParagraphStyleAttributeName : style };
        
        CGRect rect = [text boundingRectWithSize:maxSize
                                         options:opts
                                      attributes:attributes
                                         context:nil];
        textSize = rect.size;
    }
    
    return textSize;
}
                            
#pragma mark -- 显示音乐列表

- (void)showMusicList
{
    UIButton *maskButton = [[UIButton alloc]initWithFrame:self.view.bounds];
    [maskButton addTarget:self action:@selector(hideMusicList) forControlEvents:UIControlEventTouchUpInside];
    [maskButton setTag:1000];
    [self.view addSubview:maskButton];
    
    KKMusicListController *musicList = [[KKMusicListController alloc]initWithNibName:@"KKMusicListController" bundle:nil];
    musicList.delegate = self ;
    musicList.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - 200);
    [self.view addSubview:musicList.view];
    [self addChildViewController:musicList];
    
    self.listCtrl = musicList ;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.listCtrl.view.frame = CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.height - 200);
    }completion:^(BOOL finished) {
        musicList.curtPlayPath = _curtPlayPath;
    }];
}

- (void)hideMusicList
{
    [UIView animateWithDuration:0.3 animations:^{
        
        self.listCtrl.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - 200);
        
    }completion:^(BOOL finished) {
        
        [self.listCtrl.view removeFromSuperview];
        [self.listCtrl removeFromParentViewController];
        self.listCtrl = nil ;
        
        UIButton *maskButton = [self.view viewWithTag:1000];
        [maskButton removeFromSuperview];
    }];
}

#pragma mark -- KKMusicListControllerDelegate

- (void)selMusicWithPath:(NSString *)path
{
    if([_curtPlayPath isEqualToString:path]){
        return ;
    }
    
    _curtPlayPath = path ;
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(playController_PlayMusicWithPath:)]){
        [self.delegate playController_PlayMusicWithPath:_curtPlayPath];
    }
}

@end
