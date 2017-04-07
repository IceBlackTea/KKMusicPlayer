//
//  KKMusicListController.h
//  KKMusicPlayer
//
//  Created by finger on 2017/4/7.
//  Copyright © 2017年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KKMusicListControllerDelegate;
@interface KKMusicListController : UIViewController

@property(nonatomic)NSString *curtPlayPath;

@property(nonatomic,weak)id<KKMusicListControllerDelegate> delegate;

@end

@protocol KKMusicListControllerDelegate <NSObject>

- (void)selMusicWithPath:(NSString *)path ;

@end
