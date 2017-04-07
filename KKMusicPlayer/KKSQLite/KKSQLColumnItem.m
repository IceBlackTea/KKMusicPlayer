//
//  KKColumnItem.m
//  KKCommonTools
//
//  Created by finger on 17/3/15.
//  Copyright © 2017年 fingerfinger. All rights reserved.
//

#import "KKSQLColumnItem.h"

#define INTERGER @"INTERGER"//整型
#define TEXT @"TEXT"//字符
#define BLOB @"BLOB"//数据块
#define REAL @"REAL"//浮点型

@implementation KKSQLColumnItem

- (instancetype)initWithColName:(NSString *)colName colType:(SQLColumnType)colType colValue:(id)colValue
{
    self = [super init];
    if(self){
        self.columnName = colName;
        self.columnType = colType;
        self.columnValue = colValue;
    }
    return self;
}

#pragma mark -- 将列类型转换成sqlite数据支持的列类型

+ (NSString *)convertColumnType:(SQLColumnType)colType
{
    if(colType == SQLColumnTypeInteger){
        return INTERGER ;
    }
    
    if(colType == SQLColumnTypeBlob){
        return BLOB;
    }
    
    if(colType == SQLColumnTypeText){
        return TEXT;
    }
    
    if(colType == SQLColumnTypeFolat){
        return REAL ;
    }
    
    return TEXT ;
}

@end
