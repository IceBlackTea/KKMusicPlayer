//
//  KKMusicListController.m
//  KKMusicPlayer
//
//  Created by finger on 2017/4/7.
//  Copyright © 2017年 finger. All rights reserved.
//

#import "KKMusicListController.h"
#import "KKMusicFilesTableViewCell.h"
#import "KKMusicFilesManager.h"
#import "KKAVPlayer.h"

static NSString *reuseIdentifier = @"reuseIdentifier";

@interface KKMusicListController ()<UITableViewDelegate,UITableViewDataSource>
{
    __weak IBOutlet UILabel *titleLabel;
    __weak IBOutlet UITableView *musicListTable;
}
@end

@implementation KKMusicListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    musicListTable.delegate = self ;
    musicListTable.dataSource = self ;
    [musicListTable registerNib:[UINib nibWithNibName:@"KKMusicFilesTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:reuseIdentifier];
    [musicListTable setAlwaysBounceVertical:YES];
    [musicListTable setShowsVerticalScrollIndicator:YES];
    [musicListTable setTableFooterView:[UIView new]];
    
    titleLabel.text = [NSString stringWithFormat:@"音乐列表(%d)",[[KKMusicFilesManager defaultMusicFilesManager]numberOfItems]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    
    if ([_curtPlayPath isEqualToString:[[mediaEntity fileURL]absoluteString]]){
        if ([[KKAVPlayer sharedInstance]isPlay]){
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
    KKMusicEntity *mediaEntity = [[KKMusicFilesManager defaultMusicFilesManager]getItemAtIndex:indexPath.row];
    if(self.delegate && [self.delegate respondsToSelector:@selector(selMusicWithPath:)]){
        [self.delegate selMusicWithPath:[[mediaEntity fileURL]absoluteString]];
    }
}

#pragma mark -- @property

- (void)setCurtPlayPath:(NSString *)curtPlayPath
{
    _curtPlayPath = curtPlayPath;
    
    NSArray *musicArray = [[KKMusicFilesManager defaultMusicFilesManager]getMusicArray];
    
    NSInteger index = 0 ;
    for(KKMusicEntity *entity in musicArray){
        if ([_curtPlayPath isEqualToString:[[entity fileURL]absoluteString]]){
            index = [musicArray indexOfObject:entity];
            break ;
        }
    }
    
    NSUInteger indexs[2] = {0, index};
    NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:indexs length:2];
    
    if(index < [musicListTable numberOfRowsInSection:0]){
        
        [musicListTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        
        [musicListTable reloadData];
        
    }
}

@end
