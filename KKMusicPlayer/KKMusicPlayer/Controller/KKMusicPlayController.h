//
//  KKMusicPlayController.h
//  Apowersoft IOS AirMore
//
//  Created by wangxutech on 16/5/4.
//  Copyright © 2016年 Joni. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger , KKAudioPlayerStatus){
    PlayerStatusPlay,
    PlayerStatusPause
};

typedef NS_ENUM(NSInteger , KKPlayMode){
    KKPlayModeSinglePlay,
    KKPlayModeCircularPlay,
    KKPlayModeRandomPlay
};

@protocol KKMusicPlayControllerDelegate <NSObject>
@optional
- (void)playController_playNextMusic;
- (void)playController_playPreMusic;
- (void)playController_playPause;
- (void)playController_changePlayMode;
- (void)playController_seekToTime:(CGFloat)pos;
- (void)playController_PlayMusicWithPath:(NSString *)path;
@end

@interface KKMusicPlayController : UIViewController
{
    
}

@property(nonatomic,weak)id<KKMusicPlayControllerDelegate>delegate;

@property(nonatomic)UIImage *artistImage;

@property(nonatomic)NSString *musicName;
@property(nonatomic)NSString *artistName;


@property(nonatomic,assign)float sliderValue;
@property(nonatomic,assign)float totalTime;

@property(nonatomic,assign)bool currentShow;//正在显示

@property(nonatomic)KKAudioPlayerStatus playerStatue;

@property(nonatomic,assign)NSInteger playMode ;

@property(nonatomic)NSString *curtPlayPath;

@end
