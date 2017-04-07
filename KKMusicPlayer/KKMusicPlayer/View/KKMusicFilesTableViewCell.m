//
//  WXMediaFilesTableViewCell.m
//  Apowersoft IOS AirMore
//
//  Created by wangxu on 15/7/15.
//  Copyright (c) 2015年 Joni. All rights reserved.
//

#import "KKMusicFilesTableViewCell.h"
#import "UIImage+animatedGIF.h"

@interface KKMusicFilesTableViewCell()
{
    IBOutlet UIImageView  *mediaImageView;
    IBOutlet UILabel *labelTitle;
    IBOutlet UILabel *labelArtist;
    IBOutlet UIImageView  *currentPlayingImage;
    
    BOOL _isPaused;
}
@end

@implementation KKMusicFilesTableViewCell

@dynamic image,title,artist,isPlaying,isPaused;

+ (KKMusicFilesTableViewCell *)loadFromNib
{
    UINib *nib = [UINib nibWithNibName:@"KKMusicFilesTableViewCell" bundle:[NSBundle mainBundle]];
    if (nib){
        NSArray *subViews = [nib instantiateWithOwner:self options:nil];
        for (UIView *subView in subViews){
            if ([subView isKindOfClass:[KKMusicFilesTableViewCell class]]){
                [(KKMusicFilesTableViewCell *)subView _init];
                return (KKMusicFilesTableViewCell *)subView;
            }
        }
    }
    return nil;
}

- (void)dealloc
{
}

- (void)_init
{
    mediaImageView.layer.cornerRadius = CGRectGetWidth(mediaImageView.frame) / 2.0;
    mediaImageView.layer.masksToBounds = YES;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    labelTitle.textColor = [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
    labelArtist.textColor = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (BOOL)isPlaying
{
    if (currentPlayingImage.image != nil){
        return YES;
    }else{
        return NO;
    }
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    if (isPlaying){
        NSURL *gifURL =[[NSBundle mainBundle] URLForResource:@"music-Playing" withExtension:@"gif"];
        currentPlayingImage.image = [UIImage animatedImageWithAnimatedGIFURL:gifURL];
    }else{
        currentPlayingImage.image = nil;
    }
}

- (void)setIsPaused:(BOOL)isPaused
{
    _isPaused = isPaused;
    if (isPaused){
        currentPlayingImage.image = [UIImage imageNamed:@"music-paused"];
    }else{
        currentPlayingImage.image = nil;
    }
}

- (BOOL)isPaused
{
    return _isPaused;
}

- (void)setImage:(UIImage *)image
{
    if (image != nil){
        mediaImageView.image = image;
    }else{
        mediaImageView.image = [UIImage imageNamed:@"icon-music"];
    }
}

- (UIImage *)image
{
    return mediaImageView.image;
}

- (void)setTitle:(NSString *)title
{
    if (title == nil){
        labelTitle.text = @"";
    }else{
        labelTitle.text = title;
    }
}

- (NSString *)title
{
    return labelTitle.text;
}

- (void)setArtist:(NSString *)artist
{
    if (artist == nil){
        labelArtist.text = @"";
    }else{
        labelArtist.text = artist;
    }
}

- (NSString *)artist
{
    return labelArtist.text;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0].CGColor); CGContextStrokeRect(context, CGRectMake(0, rect.size.height, rect.size.width, 1));
}

@end
