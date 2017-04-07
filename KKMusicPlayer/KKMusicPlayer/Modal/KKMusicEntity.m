//
//  KKMusicEntity.m
//
//  Created by finger on 16/6/9.
//  Copyright © 2016年 finger. All rights reserved.
//

#import "KKMusicEntity.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation KKMusicEntity
{
}

- (id)initWithMediaItem:(MPMediaItem *)item
{
    self = [super init];
    
    if (self){
        
        _fileURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
        
        _title = [item valueForProperty:MPMediaItemPropertyTitle];
        
        _album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        
        _artist = [item valueForProperty:MPMediaItemPropertyArtist];
        
        _fileSize = 0 ;
        
        @autoreleasepool {
            MPMediaItemArtwork *artWork = [item valueForProperty:MPMediaItemPropertyArtwork];
            _itemArtWork = [artWork imageWithSize:artWork.bounds.size];
            _itemArtWork = [_itemArtWork scaleWithFactor:0.2 quality:0.3];
        }
        
        _seconds = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        
        _strDuration = [self convertDoubleDurationToString:_seconds];
        
        _itunesMusicFlag = true ;
        
        _localPath = @"" ;
    }
    
    return self;
}

- (id)initWithLocalFilePath:(NSString *)localFilePath
{
    self = [super init];
    
    if (self){
        
        NSURL *url = [NSURL fileURLWithPath:localFilePath];
        
        if (url != nil){
            
            _fileURL = url ;
            _localPath = localFilePath ;
            _fileSize = [[self fileDic]fileSize];
            _itunesMusicFlag = false ;
            
            @autoreleasepool {
                
                AVURLAsset *_asset = [[AVURLAsset alloc] initWithURL:url options:nil];
                
                if (_asset != nil){
                    
                    _seconds = _asset.duration.value/_asset.duration.timescale;
                    _strDuration = [self convertDoubleDurationToString:_seconds];
                    
                    for (NSString *format in [_asset availableMetadataFormats]){
                        
                        for (AVMetadataItem *metaDataItem in [_asset metadataForFormat:format]){
                            
                            if ([metaDataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]){
                                _title = [(NSString *)metaDataItem.value copy];
                                continue ;
                            }
                            
                            if ([metaDataItem.commonKey isEqualToString:AVMetadataCommonKeyArtist]){
                                _artist = [(NSString *)metaDataItem.value copy];
                                continue ;
                            }
                            
                            if ([metaDataItem.commonKey isEqualToString:AVMetadataCommonKeyArtwork]){
                                
                                @try{
                                    if ([metaDataItem.value isKindOfClass:[NSData class]]){
                                        _itemArtWork = [[UIImage alloc] initWithData:(NSData *)metaDataItem.value];
                                        _itemArtWork = [_itemArtWork scaleWithFactor:0.2 quality:0.3];
                                    }else if([metaDataItem.value isKindOfClass:[NSDictionary class]]){
                                        _itemArtWork = [[UIImage alloc] initWithData:[(NSDictionary*)metaDataItem.value objectForKey:@"data"]];
                                        _itemArtWork = [_itemArtWork scaleWithFactor:0.2 quality:0.3];
                                    }
                                }@catch (NSException *exception){
                                }
                                
                                continue ;
                            }
                            
                            if ([metaDataItem.commonKey isEqualToString:AVMetadataCommonKeyAlbumName]){
                                
                                _album = [(NSString *)metaDataItem.value copy];
                                
                                continue ;
                                
                            }
                        }
                    }
                    
                    if(!_title.length){
                        _title = [[_localPath lastPathComponent]stringByDeletingPathExtension];
                    }
                    
                }else{
                    return nil;
                }
                
            }
        }
    }
    return self;
}

#pragma mark -- @property

- (NSString *)album
{
    if(!_album.length){
        return @"";
    }
    
    return _album ;
}

- (NSString *)artist
{
    if(!_artist.length){
        return @"";
    }
    
    return _artist ;
}

- (NSString *)title
{
    if(!_title.length){
        return @"";
    }
    
    return _title ;
}

- (NSString *)strDuration
{
    if(!_strDuration.length){
        return @"";
    }
    
    return _strDuration ;
}

#pragma mark -- 数值转换成时间

- (NSString *)convertDoubleDurationToString:(NSTimeInterval)duration;
{
    int hour = duration / 3600;
    int minute = (duration - hour*3600) / 60;
    int seconds = (duration - hour *3600 - minute*60);
    NSString *strDuration  = @"";
    if (hour > 9){
        strDuration = [NSString stringWithFormat:@"%d:",hour];
    }else if (hour >0 && hour<10){
        strDuration = [NSString stringWithFormat:@"0%d:",hour];
    }
    
    if (minute > 9 ){
        strDuration = [strDuration stringByAppendingFormat:@"%d:",minute];
    }else if (minute > 0 && minute <10){
        strDuration = [strDuration stringByAppendingFormat:@"0%d:",minute];
    }else{
        strDuration = [strDuration stringByAppendingFormat:@"00:"];
    }
    
    if (seconds > 9){
        strDuration = [strDuration stringByAppendingFormat:@"%d",seconds];
    }else if (seconds > 0 && seconds <10){
        strDuration = [strDuration stringByAppendingFormat:@"0%d",seconds];
    }else{
        strDuration = [strDuration stringByAppendingFormat:@"00"];
    }
    
    return strDuration;
}

- (NSDictionary *)fileDic
{
    return [[NSFileManager defaultManager] attributesOfItemAtPath:_localPath error:nil];
}

#pragma mark -- 获取封面

- (void)getImage:(void (^)(UIImage *image))handler
{
    if (_itemArtWork != nil){
        
        handler(_itemArtWork);
        
    }else{
        
        dispatch_async(dispatch_get_global_queue(0, 0),^{
            
            @autoreleasepool {
                
                AVURLAsset *_asset = [[AVURLAsset alloc] initWithURL:[self fileURL] options:nil];
                
                bool canBreak = false ;
                
                for (NSString *format in [_asset availableMetadataFormats]){
                    
                    for (AVMetadataItem *metaDataItem in [_asset metadataForFormat:format]){
                        
                        if ([metaDataItem.commonKey isEqualToString:AVMetadataCommonKeyArtwork]){
                            
                            @try{
                                
                                if ([metaDataItem.value isKindOfClass:[NSData class]]){
                                    
                                    _itemArtWork = [[UIImage alloc] initWithData:(NSData *)metaDataItem.value];
                                    _itemArtWork = [_itemArtWork scaleWithFactor:0.2 quality:0.3];
                                    
                                    canBreak = true ;
                                    
                                    break ;
                                    
                                }else if([metaDataItem.value isKindOfClass:[NSDictionary class]]){
                                    
                                    _itemArtWork = [[UIImage alloc] initWithData:[(NSDictionary*)metaDataItem.value objectForKey:@"data"]];
                                    _itemArtWork = [_itemArtWork scaleWithFactor:0.2 quality:0.3];
                                    
                                    canBreak = true ;
                                    
                                    break ;
                                }
                                
                            }@catch (NSException *exception){
                            }
                        }
                    }
                    
                    if(canBreak){
                        break ;
                    }
                    
                }
                handler(_itemArtWork);
            }
        });
    }
}

- (void)getFullImage:(void (^)(UIImage *image))handler
{
    dispatch_async(dispatch_get_global_queue(0, 0),^{
        
        @autoreleasepool {
            
            AVURLAsset *_asset = [[AVURLAsset alloc] initWithURL:[self fileURL] options:nil];
            
            UIImage *image = nil ;
            
            bool canBreak = false ;
            
            for (NSString *format in [_asset availableMetadataFormats]){
                
                for (AVMetadataItem *metaDataItem in [_asset metadataForFormat:format]){
                    
                    if ([metaDataItem.commonKey isEqualToString:AVMetadataCommonKeyArtwork]){
                        
                        @try{
                            
                            if ([metaDataItem.value isKindOfClass:[NSData class]]){
                                
                                image = [[UIImage alloc] initWithData:(NSData *)metaDataItem.value];
                                
                                canBreak = true ;
                                
                                break ;
                                
                            }else if([metaDataItem.value isKindOfClass:[NSDictionary class]]){
                                
                                image = [[UIImage alloc] initWithData:[(NSDictionary*)metaDataItem.value objectForKey:@"data"]];
                                
                                canBreak = true ;
                                
                                break ;
                            }
                            
                        }@catch (NSException *exception){
                        }
                        
                    }
                }
                
                if(canBreak){
                    break ;
                }
                
            }
            handler(image);
        }
    });
}

@end
