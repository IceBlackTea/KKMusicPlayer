//
//  KKMediaFilesTableViewCell.h
//
//  Created by finger on 15/7/15.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKMusicFilesTableViewCell : UITableViewCell
{
    
}

@property(nonatomic , assign)UIImage *image;
@property(nonatomic , assign)NSString *title;
@property(nonatomic , assign)NSString *artist;

@property(nonatomic , assign)BOOL isPlaying;
@property(nonatomic , assign)BOOL isPaused;

+ (KKMusicFilesTableViewCell *)loadFromNib;


@end
