//
//  KKMediaFilesManager.m
//  Apowersoft IOS AirMore
//
//  Created by finger on 15/7/15.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKMusicFilesManager.h"
#import "KKSQLite.h"

#define kNSPathStore2Characters  @"NSPathStore2"

#define MUSIC_DATABASE @"KKMusicInfoDatabase.db"

#define LOCAL_MUSIC_TABLE @"local_music_table"
#define ITNUES_MUSIC_TABLE @"itnues_music_table"

typedef void(^complateCallback)();
typedef void(^progressCallback)(NSInteger readCount,NSInteger totalCount);

static KKMusicFilesManager *_defaultManager = nil;

@interface KKMusicFilesManager ()

@property (nonatomic,assign)bool isStillLoading;

@end

@implementation KKMusicFilesManager
{
    NSMutableArray *_mediasArray;
    
    NSDateFormatter *dateFormatter;
    
    KKSQLite *sqliteDatabase;
    
    NSInteger curtProgressCount;
    NSInteger totalCount ;
    NSInteger localMusicCount;
    NSInteger itnuesMusicCount;
    
    complateCallback complateHandler ;
    progressCallback progressHandler;
}

@synthesize isStillLoading;

+ (KKMusicFilesManager *)defaultMusicFilesManager
{
    if (_defaultManager == nil){
        _defaultManager = [[KKMusicFilesManager alloc] init];
    }
    return _defaultManager;
}

- (id)init
{
    self = [super init];
    
    if(self){
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        _mediasArray = [[NSMutableArray alloc]init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dbFilePath = [documentsDirectory stringByAppendingPathComponent:MUSIC_DATABASE];
        //[[NSFileManager defaultManager]removeItemAtPath:dbFilePath error:nil];
        
        sqliteDatabase = [[KKSQLite alloc]initDataBaseWithPath:dbFilePath];
        
        if(sqliteDatabase){
            
            NSMutableArray *array = [[NSMutableArray alloc]init];
            
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"itemArtWork" colType:SQLColumnTypeBlob colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"itunesMusicFlag" colType:SQLColumnTypeInteger colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"localPath" colType:SQLColumnTypeText colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"title" colType:SQLColumnTypeText colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"artist" colType:SQLColumnTypeText colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"album" colType:SQLColumnTypeText colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"fileURL" colType:SQLColumnTypeText colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"seconds" colType:SQLColumnTypeInteger colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"strDuration" colType:SQLColumnTypeText colValue:nil]];
            [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"fileSize" colType:SQLColumnTypeInteger colValue:nil]];
            
            [sqliteDatabase createTableWithName:LOCAL_MUSIC_TABLE columns:array];
            [sqliteDatabase createTableWithName:ITNUES_MUSIC_TABLE columns:array];
        }
    }
    return self ;
}

- (void)dealloc
{
    [sqliteDatabase closeDataBase];
}

#pragma mark -- 本地音乐库路径

- (NSString *)localMusicLibraryPath
{
    NSString *localAudioLibraryPath = [[NSBundle mainBundle]bundlePath];
    localAudioLibraryPath = [localAudioLibraryPath stringByAppendingPathComponent:@"MusicResource"];
    
    return localAudioLibraryPath ;
}

#pragma mark -- 音乐加载，第一次运行程序时，将加载的音乐信息存储到数据库，下次读取音乐时直接从数据库读取

- (void)shouldUpdateMusic:(void(^)(bool rst))handler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString *localAudioLibraryPath = [self localMusicLibraryPath];
        
        NSArray *subItems = [[NSFileManager defaultManager] subpathsAtPath:localAudioLibraryPath];
        
        MPMediaQuery *query = [MPMediaQuery songsQuery];
        NSArray *theList = [query items];
        
        if(localMusicCount != subItems.count||
           itnuesMusicCount != theList.count){
            
            localMusicCount = subItems.count ;
            itnuesMusicCount = theList.count ;
            
            if(handler){
                handler(true);
            }
            
            return ;
        }
        
        localMusicCount = subItems.count ;
        itnuesMusicCount = theList.count ;
        
        if(handler){
            handler(false);
        }
        
    });
}

- (void)readMeidaFiles:(void(^)())handler progress:(void(^)(NSInteger curtCount,NSInteger totalCount))progress
{
    complateHandler = [handler copy];
    progressHandler = [progress copy];
    
    if(isStillLoading){
        
        if (complateHandler != nil){
            complateHandler();
        }
        
        return ;
    }
    
    isStillLoading = true ;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [self readAllMusicFiles];
        
        if (complateHandler != nil){
            complateHandler();
        }
        isStillLoading = false ;
        
    });
}

- (void)readAllMusicFiles
{
    @autoreleasepool {
        
        _mediasArray = [[NSMutableArray alloc]init];
        
        NSString *localAudioLibraryPath = [self localMusicLibraryPath];
        
        NSArray *subItems = [[NSFileManager defaultManager] subpathsAtPath:localAudioLibraryPath];
        
        MPMediaQuery *query = [[MPMediaQuery alloc]init];
        MPMediaPropertyPredicate *musicPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInt:MPMediaTypeMusic] forProperty: MPMediaItemPropertyMediaType];
        [query addFilterPredicate:musicPredicate];
        NSArray *theList = [query items];
        
        localMusicCount = [sqliteDatabase tableRowCount:LOCAL_MUSIC_TABLE];
        itnuesMusicCount = [sqliteDatabase tableRowCount:ITNUES_MUSIC_TABLE];
        
        curtProgressCount = 0 ;
        totalCount = theList.count + subItems.count ;
        
        bool shouldShowProgress = false ;
        
        if((localMusicCount != subItems.count && subItems.count >= 50) ||
           (itnuesMusicCount != theList.count && theList.count >= 50)){
            shouldShowProgress = true ;
        }
        
        if(localMusicCount != subItems.count){
            
            [sqliteDatabase clearTable:LOCAL_MUSIC_TABLE];
            
            for (NSString *itemName in subItems){
                
                if (![itemName isKindOfClass:NSClassFromString(kNSPathStore2Characters)]){
                    
                    NSString *itemPath = [localAudioLibraryPath stringByAppendingPathComponent:itemName];
                    
                    KKMusicEntity *audioEntity = [[KKMusicEntity alloc] initWithLocalFilePath:itemPath];
                    
                    if (audioEntity != nil){
                        
                        [_mediasArray addObject:audioEntity];
                        
                        [self addMusicInfoToDatabase:LOCAL_MUSIC_TABLE entity:audioEntity];
                    }
                    
                    ++curtProgressCount ;
                    
                    if(shouldShowProgress && progressHandler){
                        progressHandler(curtProgressCount,totalCount);
                    }
                }
            }
            
            localMusicCount = subItems.count ;
            
        }else{
            [self initMusicInfoFromDatabase:LOCAL_MUSIC_TABLE progress:nil];
        }
        
        //读取itnues音乐
        if(itnuesMusicCount != theList.count){
            
            [sqliteDatabase clearTable:ITNUES_MUSIC_TABLE];
            
            for (MPMediaItem *item in theList){
                
                KKMusicEntity *newEntity = [[KKMusicEntity alloc] initWithMediaItem:item];
                if(newEntity){
                    
                    [_mediasArray addObject:newEntity];
                    
                    [self addMusicInfoToDatabase:ITNUES_MUSIC_TABLE entity:newEntity];
                    
                }
                
                ++curtProgressCount ;
                
                if(shouldShowProgress && progressHandler){
                    progressHandler(curtProgressCount,totalCount);
                }
                
            }
            
            itnuesMusicCount = theList.count ;
            
        }else{
            [self initMusicInfoFromDatabase:ITNUES_MUSIC_TABLE progress:nil];
        }
        
        [query removeFilterPredicate:musicPredicate];
    }
}

#pragma mark -- 全部的歌曲数量，包含itnues和沙盒中的音乐

- (NSInteger)numberOfItems
{
    return _mediasArray.count;
}

#pragma mark -- 沙盒中的音乐数量

- (NSInteger)numberOfLocalItems
{
    return localMusicCount;
}

#pragma mark -- 音乐对象的获取

- (NSArray*)getMusicArray
{
    return _mediasArray;
}

- (KKMusicEntity *)getItemAtIndex:(NSInteger)index
{
    if (_mediasArray == nil || _mediasArray.count == 0){
        return nil;
    }
    if (index < 0 || index > _mediasArray.count - 1){
        return nil;
    }
    return [_mediasArray objectAtIndex:index];
}

- (KKMusicEntity *)getItemWithMediaName:(NSString *)mediaName
{
    if (_mediasArray == nil || _mediasArray.count == 0){
        return nil;
    }
    
    for (KKMusicEntity *entity in _mediasArray){
        if ([[entity title] isEqualToString:mediaName]){
            return entity;
        }
    }
    
    return nil;
}

#pragma mark -- 根据音乐的路径获取音乐在音乐库中的索引

- (NSInteger)getMusicIndexWithLocalPath:(NSString*)localPath
{
    if (_mediasArray == nil || _mediasArray.count == 0){
        return -1;
    }
    
    for (int i = 0 ; i < _mediasArray.count; i++){
        KKMusicEntity *mediaEntity = [_mediasArray objectAtIndex:i];
        if ([mediaEntity.localPath isEqualToString:localPath] && ![mediaEntity itunesMusicFlag]){
            return i;
        }
    }
    
    return -1;
}

#pragma mark -- 添加音乐信息到数据库

- (void)addMusicInfoToDatabase:(NSString*)tbName entity:(KKMusicEntity*)audioEntity
{
    NSMutableArray *array = [[NSMutableArray alloc]init];
    
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"itemArtWork" colType:SQLColumnTypeBlob colValue:UIImagePNGRepresentation(audioEntity.itemArtWork)]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"itunesMusicFlag" colType:SQLColumnTypeInteger colValue:[NSNumber numberWithInt:audioEntity.itunesMusicFlag]]];
    
    NSString *fileKey = audioEntity.localPath ;
    fileKey = [[fileKey componentsSeparatedByString:@"/Documents/"]lastObject];
    if(fileKey == nil){
        fileKey = @"" ;
    }
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"localPath" colType:SQLColumnTypeText colValue:fileKey]];
 
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"title" colType:SQLColumnTypeText colValue:audioEntity.title]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"artist" colType:SQLColumnTypeText colValue:audioEntity.artist]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"album" colType:SQLColumnTypeText colValue:audioEntity.album]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"fileURL" colType:SQLColumnTypeText colValue:[audioEntity.fileURL absoluteString]]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"seconds" colType:SQLColumnTypeInteger colValue:[NSNumber numberWithDouble:audioEntity.seconds]]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"strDuration" colType:SQLColumnTypeText colValue:audioEntity.strDuration]];
    [array addObject:[[KKSQLColumnItem alloc]initWithColName:@"fileSize" colType:SQLColumnTypeInteger colValue:[NSNumber numberWithLongLong:audioEntity.fileSize]]];
    
    [sqliteDatabase addOneRowDataToTable:tbName data:array];
}

#pragma mark -- 从数据库中加载音乐信息

- (void)initMusicInfoFromDatabase:(NSString*)tbName progress:(void(^)(NSInteger curtCount,NSInteger totalCount))progressHandler
{
    KKSQLQueryResultSet *resultSet = [sqliteDatabase loadAllDataWithTableName:tbName];
    
    while ([resultSet next]) {
        
        KKMusicEntity *audioEntity = [[KKMusicEntity alloc]init];
        
        audioEntity.title = [resultSet stringValueWithColumnName:@"title"];
        
        audioEntity.itunesMusicFlag = [resultSet boolValueWithColumnName:@"itunesMusicFlag"];
        
        if(!audioEntity.itunesMusicFlag){
            
            NSString *fileName = [[resultSet stringValueWithColumnName:@"localPath"]lastPathComponent];
            audioEntity.localPath = [[self localMusicLibraryPath] stringByAppendingPathComponent:fileName];
            
            audioEntity.fileURL = [NSURL fileURLWithPath:audioEntity.localPath];
            
        }else{
            
            audioEntity.fileURL = [NSURL URLWithString:[resultSet stringValueWithColumnName:@"fileURL"]];
            audioEntity.localPath = @"";
        }
        
        NSData *data = [resultSet dataValueWithColumnName:@"itemArtWork"];
        audioEntity.itemArtWork = [UIImage imageWithData:data];
        
        audioEntity.album = [resultSet stringValueWithColumnName:@"album"];
        
        audioEntity.artist = [resultSet stringValueWithColumnName:@"artist"];
        
        audioEntity.seconds = [resultSet floatValueWithColumnName:@"seconds"];
        
        audioEntity.strDuration = [resultSet stringValueWithColumnName:@"strDuration"];
        
        audioEntity.fileSize = [resultSet intValueWithColumnName:@"fileSize"];
        
        [_mediasArray addObject:audioEntity];
        
        ++curtProgressCount ;
    }
    
    [resultSet freeResultSet];
}

@end

